package com.invogue.app

import android.content.Context
import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.pose.PoseDetection
import com.google.mlkit.vision.pose.PoseLandmark
import com.google.mlkit.vision.pose.defaults.PoseDetectorOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/** Tells whether a photo shows a person head to toe, with ML Kit's pose detection on the device. */
object PhotoCheck {
    private const val CHANNEL = "in_vogue/photo_check"

    /** Landmarks that must be in the photo for it to count as head to toe. */
    private val landmarks = listOf(
        PoseLandmark.NOSE,
        PoseLandmark.LEFT_ANKLE,
        PoseLandmark.RIGHT_ANKLE,
    )

    /** ML Kit's in-frame likelihood below which a landmark counts as outside the photo. */
    private const val MIN_IN_FRAME = 0.5f

    fun register(context: Context, messenger: BinaryMessenger) {
        val detector = PoseDetection.getClient(
            PoseDetectorOptions.Builder()
                .setDetectorMode(PoseDetectorOptions.SINGLE_IMAGE_MODE)
                .build(),
        )
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "isFullLength") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val path = call.argument<String>("path")
            if (path == null) {
                result.error("bad_arguments", "A path is required", null)
                return@setMethodCallHandler
            }
            val image = try {
                InputImage.fromFilePath(context, Uri.fromFile(File(path)))
            } catch (error: Exception) {
                result.error("unreadable", error.message, null)
                return@setMethodCallHandler
            }
            detector.process(image)
                .addOnSuccessListener { pose ->
                    result.success(
                        landmarks.all { type ->
                            (pose.getPoseLandmark(type)?.inFrameLikelihood ?: 0f) >= MIN_IN_FRAME
                        },
                    )
                }
                .addOnFailureListener { error -> result.error("unreadable", error.message, null) }
        }
    }
}
