package com.example.codesnap

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "codesnap/storage_picker"
    private val REQ_PICK_IMAGE = 1001
    private val REQ_PICK_VIDEO = 1002
    private val REQ_PICK_DOC = 1003
    private val REQ_TAKE_PHOTO = 1004

    private var pendingResult: MethodChannel.Result? = null
    private var pendingMediaType: String = "image"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickImage" -> {
                    val fromCamera = call.argument<Boolean>("fromCamera") ?: false
                    pendingResult = result
                    pendingMediaType = "image"
                    if (fromCamera) {
                        val intent = Intent(android.provider.MediaStore.ACTION_IMAGE_CAPTURE)
                        startActivityForResult(intent, REQ_TAKE_PHOTO)
                    } else {
                        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                            type = "image/*"
                            addCategory(Intent.CATEGORY_OPENABLE)
                        }
                        startActivityForResult(Intent.createChooser(intent, "Select Picture"), REQ_PICK_IMAGE)
                    }
                }
                "pickVideo" -> {
                    pendingResult = result
                    pendingMediaType = "video"
                    val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                        type = "video/*"
                        addCategory(Intent.CATEGORY_OPENABLE)
                    }
                    startActivityForResult(Intent.createChooser(intent, "Select Video"), REQ_PICK_VIDEO)
                }
                "pickDocument" -> {
                    pendingResult = result
                    pendingMediaType = "document"
                    val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                        type = "*/*"
                        addCategory(Intent.CATEGORY_OPENABLE)
                    }
                    startActivityForResult(Intent.createChooser(intent, "Select Document"), REQ_PICK_DOC)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (pendingResult == null) return

        if (resultCode != Activity.RESULT_OK || data == null) {
            pendingResult?.success(null)
            pendingResult = null
            return
        }

        try {
            if (requestCode == REQ_TAKE_PHOTO) {
                val bitmap = data.extras?.get("data") as? android.graphics.Bitmap
                if (bitmap != null) {
                    val cacheFile = File(cacheDir, "camera_${System.currentTimeMillis()}.jpg")
                    val out = FileOutputStream(cacheFile)
                    bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 90, out)
                    out.flush()
                    out.close()

                    val bytes = cacheFile.readBytes()
                    val base64Data = "data:image/jpeg;base64," + Base64.encodeToString(bytes, Base64.NO_WRAP)

                    val map = mapOf(
                        "pathOrDataUrl" to base64Data,
                        "fileName" to cacheFile.name,
                        "fileSize" to cacheFile.length(),
                        "mediaType" to "image",
                        "extension" to "jpg"
                    )
                    pendingResult?.success(map)
                } else {
                    pendingResult?.success(null)
                }
                pendingResult = null
                return
            }

            val uri: Uri? = data.data
            if (uri == null) {
                pendingResult?.success(null)
                pendingResult = null
                return
            }

            var fileName = "file_${System.currentTimeMillis()}"
            var fileSize = 0L

            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                    if (nameIndex != -1) {
                        fileName = cursor.getString(nameIndex) ?: fileName
                    }
                    if (sizeIndex != -1) {
                        fileSize = cursor.getLong(sizeIndex)
                    }
                }
            }

            val extension = fileName.substringAfterLast('.', "")
            val inputStream: InputStream? = contentResolver.openInputStream(uri)

            if (inputStream != null) {
                val bytes = inputStream.readBytes()
                inputStream.close()
                val actualSize = if (fileSize > 0) fileSize else bytes.size.toLong()

                val mime = contentResolver.getType(uri) ?: when (pendingMediaType) {
                    "image" -> "image/jpeg"
                    "video" -> "video/mp4"
                    else -> "application/octet-stream"
                }

                val cacheFile = File(cacheDir, fileName)
                val fos = FileOutputStream(cacheFile)
                fos.write(bytes)
                fos.flush()
                fos.close()

                val pathOrDataUrl = if (pendingMediaType == "image") {
                    "data:$mime;base64," + Base64.encodeToString(bytes, Base64.NO_WRAP)
                } else {
                    cacheFile.absolutePath
                }

                val map = mapOf(
                    "pathOrDataUrl" to pathOrDataUrl,
                    "fileName" to fileName,
                    "fileSize" to actualSize,
                    "mediaType" to pendingMediaType,
                    "extension" to extension
                )
                pendingResult?.success(map)
            } else {
                pendingResult?.success(null)
            }
        } catch (e: Exception) {
            pendingResult?.error("PICK_ERROR", e.localizedMessage, null)
        } finally {
            pendingResult = null
        }
    }
}
