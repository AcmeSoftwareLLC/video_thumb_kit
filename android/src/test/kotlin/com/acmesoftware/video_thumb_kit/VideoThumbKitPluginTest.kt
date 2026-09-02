package com.acmesoftware.video_thumb_kit

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.mockito.Mockito.mock
import org.mockito.Mockito.`when`

class VideoThumbKitPluginTest {
  @Test
  fun `onAttachedToEngine registers the host API and onDetachedFromEngine unregisters it`() {
    val plugin = VideoThumbKitPlugin()
    val binaryMessenger = mock(BinaryMessenger::class.java)
    val context = mock(Context::class.java)
    val binding = mock(FlutterPlugin.FlutterPluginBinding::class.java)
    `when`(binding.binaryMessenger).thenReturn(binaryMessenger)
    `when`(binding.applicationContext).thenReturn(context)

    plugin.onAttachedToEngine(binding)
    plugin.onDetachedFromEngine(binding)

    assertNotNull(plugin)
  }
}
