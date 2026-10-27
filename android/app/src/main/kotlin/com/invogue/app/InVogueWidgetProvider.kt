package com.invogue.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import kotlin.math.ceil
import org.json.JSONObject

/**
 * The home-screen widget: the day's weather on a Rouge slab beside the person in the day's outfit.
 *
 * The app keeps today's and tomorrow's days, their words already in the person's language; the
 * widget picks the day itself, as Home does, and is redrawn at 06:00, 09:00 and midnight.
 */
class InVogueWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val content = widgetData.getString(CONTENT_KEY, null)?.let(::parse)
    for (id in appWidgetIds) {
      val options = appWidgetManager.getAppWidgetOptions(id)
      val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
      appWidgetManager.updateAppWidget(id, views(context, content, sizeOf(options), width))
    }
  }

  override fun onAppWidgetOptionsChanged(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetId: Int,
      newOptions: Bundle,
  ) {
    super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    onUpdate(context, appWidgetManager, intArrayOf(appWidgetId), HomeWidgetPlugin.getData(context))
  }

  private enum class Size(val layout: Int, val numeral: Float, val pictureSide: Int) {
    SMALL(R.layout.in_vogue_widget_small, 104f, 0),
    MEDIUM(R.layout.in_vogue_widget_medium, 118f, 480),
    LARGE(R.layout.in_vogue_widget_large, 150f, 720),
  }

  private class Day(
      val date: String,
      val today: String,
      val tomorrow: String,
      val dateLine: String,
      val temperature: Int,
      val condition: String,
      val feelsLike: String,
      val glyph: String,
      val picture: String?,
      val waitingPhoto: String?,
      val gettingReady: String,
      val spokenToday: String,
      val spokenTomorrow: String,
      val link: String,
  )

  private class Content(val preferred: String, val savedLine: String, val days: List<Day>)

  /** The day on show, with its kicker, date line and spoken label as they read now. */
  private class Shown(val day: Day, val kicker: String, val dateLine: String, val spoken: String)

  private fun views(context: Context, content: Content?, size: Size, width: Int): RemoteViews {
    val shown = content?.let { shown(it, Calendar.getInstance()) }
    if (shown == null) {
      return RemoteViews(context.packageName, R.layout.in_vogue_widget_empty).apply {
        setOnClickPendingIntent(
            R.id.widget_root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
        )
      }
    }
    val day = shown.day
    return RemoteViews(context.packageName, size.layout).apply {
      setTextViewText(R.id.widget_kicker, shown.kicker)
      setViewVisibility(
          R.id.widget_kicker,
          if (shown.kicker.isEmpty()) View.GONE else View.VISIBLE,
      )
      if (size != Size.SMALL) setTextViewText(R.id.widget_date, shown.dateLine)
      setImageViewBitmap(R.id.widget_numeral, numeral(context, day.temperature, size, width))
      setImageViewResource(R.id.widget_glyph, glyph(day.glyph))
      setTextViewText(R.id.widget_condition, day.condition)
      if (size == Size.LARGE) setTextViewText(R.id.widget_feels, day.feelsLike)
      if (size != Size.SMALL) picture(this, day, size)
      setContentDescription(R.id.widget_root, shown.spoken)
      setOnClickPendingIntent(
          R.id.widget_root,
          HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse(day.link)),
      )
    }
  }

  /** The portrait on studio grey, or the person's photo faded under "Getting ready". */
  private fun picture(views: RemoteViews, day: Day, size: Size) {
    val portrait = decode(day.picture, size.pictureSide)
    if (portrait != null) {
      views.setImageViewBitmap(R.id.widget_picture, portrait)
      views.setInt(R.id.widget_picture, "setImageAlpha", OPAQUE)
      views.setInt(R.id.widget_picture, "setBackgroundColor", STUDIO)
      views.setViewVisibility(R.id.widget_waiting, View.GONE)
      return
    }
    val waiting = decode(day.waitingPhoto, size.pictureSide)
    if (waiting != null) {
      views.setImageViewBitmap(R.id.widget_picture, waiting)
    } else {
      views.setImageViewResource(R.id.widget_picture, android.R.color.transparent)
    }
    views.setInt(R.id.widget_picture, "setImageAlpha", WAITING_ALPHA)
    views.setInt(R.id.widget_picture, "setBackgroundColor", Color.TRANSPARENT)
    views.setTextViewText(R.id.widget_waiting, day.gettingReady)
    views.setViewVisibility(R.id.widget_waiting, View.VISIBLE)
  }

  /**
   * The day to show at [now]: always today when the person chose it, else today from 06:00 to
   * 08:59 and tomorrow otherwise, as Home's ForecastDay.shownAt in the app. Without that day, the
   * newest one, with the time it was saved instead of its date.
   */
  private fun shown(content: Content, now: Calendar): Shown? {
    val today = key(now)
    val tomorrow = key((now.clone() as Calendar).apply { add(Calendar.DAY_OF_YEAR, 1) })
    val hour = now.get(Calendar.HOUR_OF_DAY)
    val target = if (content.preferred == "today" || hour in 6..8) today else tomorrow
    content.days.firstOrNull { it.date == target }?.let { day ->
      val isToday = day.date == today
      return Shown(
          day = day,
          kicker = if (isToday) day.today else day.tomorrow,
          dateLine = day.dateLine,
          spoken = if (isToday) day.spokenToday else day.spokenTomorrow,
      )
    }
    val newest = content.days.maxByOrNull { it.date } ?: return null
    return Shown(newest, kicker = "", dateLine = content.savedLine, spoken = content.savedLine)
  }

  private fun sizeOf(options: Bundle): Size {
    val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
    val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT)
    return when {
      width == 0 -> Size.LARGE
      width >= 250 && height >= 250 -> Size.LARGE
      width >= 250 -> Size.MEDIUM
      else -> Size.SMALL
    }
  }

  private fun glyph(name: String): Int =
      when (name) {
        "sun" -> R.drawable.widget_glyph_sun
        "cloud-sun" -> R.drawable.widget_glyph_cloud_sun
        "cloud" -> R.drawable.widget_glyph_cloud
        "cloud-fog" -> R.drawable.widget_glyph_cloud_fog
        "cloud-rain" -> R.drawable.widget_glyph_cloud_rain
        "cloud-snow" -> R.drawable.widget_glyph_cloud_snow
        "cloud-lightning" -> R.drawable.widget_glyph_cloud_lightning
        "wind" -> R.drawable.widget_glyph_wind
        else -> R.drawable.widget_glyph_cloud
      }

  /**
   * The temperature as a picture at its size class's size, or smaller so it fits on one line in
   * the room the slab of a widget [width] dp wide leaves it. Not text: the launcher draws a
   * widget's text in the phone's font, wider than ours, so a numeral TextView sized here still
   * showed "20°" as "2" (October 27). The ImageView shrinks the picture further when the widget is
   * narrower or shorter than its options say.
   */
  private fun numeral(context: Context, temperature: Int, size: Size, width: Int): Bitmap {
    val density = context.resources.displayMetrics.density
    // The slab less its padding.
    val room =
        when (size) {
          Size.SMALL -> width - 30f
          // The condition keeps the rest of the row.
          Size.MEDIUM -> (width * 206f / 338f - 30f) * 0.72f
          Size.LARGE -> width * 154f / 338f - 16f
        }
    val full = Numeral(context, temperature, size.numeral * density)
    val wide = full.bounds.width() / density
    if (width == 0 || room <= 0f || wide <= room) return full.picture()
    return Numeral(context, temperature, full.textSize * room / wide).picture()
  }

  /**
   * The temperature in the numeral's type, [textSize] px: light and tight, its degree sign at 86%.
   * Around the start of the baseline, [bounds] runs from the figures' first ink, so they line up
   * with the words above, to their end, and over the spec's line height: 0.74 of the size, the
   * font's own trimmed evenly, as the app's widget preview sets it.
   */
  private class Numeral(private val context: Context, temperature: Int, val textSize: Float) {
    private val figures = "$temperature"
    private val figurePaint = paint(textSize)
    private val degreePaint = paint(textSize * 0.86f)
    private val degreeX = figurePaint.measureText(figures)

    val bounds: RectF = run {
      val font = figurePaint.fontMetrics
      val trim = (font.descent - font.ascent - 0.74f * textSize) / 2
      val ink = Rect().also { figurePaint.getTextBounds(figures, 0, figures.length, it) }
      RectF(
          ink.left.toFloat(),
          minOf(font.ascent + trim, ink.top.toFloat()),
          degreeX + degreePaint.measureText(DEGREE),
          maxOf(font.descent - trim, ink.bottom.toFloat()),
      )
    }

    fun picture(): Bitmap {
      val picture =
          Bitmap.createBitmap(
              context.resources.displayMetrics,
              ceil(bounds.width()).toInt(),
              ceil(bounds.height()).toInt(),
              Bitmap.Config.ARGB_8888,
          )
      Canvas(picture).apply {
        translate(-bounds.left, -bounds.top)
        drawText(figures, 0f, 0f, figurePaint)
        drawText(DEGREE, degreeX, 0f, degreePaint)
      }
      return picture
    }

    /** Sofia Sans Extra Condensed at weight 300, 2.5% tight, in Rose. */
    private fun paint(size: Float): Paint =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
          color = context.getColor(R.color.widget_rose)
          letterSpacing = -0.025f
          this.textSize = size
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            setTypeface(context.resources.getFont(R.font.sofia_sans_extra_condensed))
            setFontVariationSettings("'wght' 300")
          } else {
            // Font resources and weights need Android 8.
            setTypeface(Typeface.create("sans-serif-light", Typeface.NORMAL))
          }
        }
  }

  /** The picture at [path], at most about [side] pixels on its long side; null when missing. */
  private fun decode(path: String?, side: Int): Bitmap? {
    if (path == null || side == 0 || !File(path).exists()) return null
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeFile(path, bounds)
    if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
    var sample = 1
    while (maxOf(bounds.outWidth, bounds.outHeight) / (sample * 2) >= side) sample *= 2
    return BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
  }

  private fun key(day: Calendar): String =
      SimpleDateFormat("yyyy-MM-dd", Locale.US).format(day.time)

  private fun parse(json: String): Content? =
      try {
        val root = JSONObject(json)
        val days = root.getJSONArray("days")
        Content(
            preferred = root.getString("preferred"),
            savedLine = root.getString("savedLine"),
            days =
                (0 until days.length()).map { index ->
                  val day = days.getJSONObject(index)
                  Day(
                      date = day.getString("date"),
                      today = day.getString("today"),
                      tomorrow = day.getString("tomorrow"),
                      dateLine = day.getString("dateLine"),
                      temperature = day.getInt("temperature"),
                      condition = day.getString("condition"),
                      feelsLike = day.getString("feelsLike"),
                      glyph = day.getString("glyph"),
                      picture = day.optionalString("picture"),
                      waitingPhoto = day.optionalString("waitingPhoto"),
                      gettingReady = day.getString("gettingReady"),
                      spokenToday = day.getString("spokenToday"),
                      spokenTomorrow = day.getString("spokenTomorrow"),
                      link = day.getString("link"),
                  )
                },
        )
      } catch (error: org.json.JSONException) {
        null
      }

  private fun JSONObject.optionalString(name: String): String? =
      if (isNull(name)) null else getString(name)

  private companion object {
    /** Where the app keeps the widget's content (HomeWidgetDataSourceImpl.contentKey). */
    const val CONTENT_KEY = "in_vogue_widget"
    const val DEGREE = "°"
    const val OPAQUE = 255

    /** The waiting photo at 28%. */
    const val WAITING_ALPHA = 71
    val STUDIO: Int = Color.rgb(0xED, 0xED, 0xEB)
  }
}
