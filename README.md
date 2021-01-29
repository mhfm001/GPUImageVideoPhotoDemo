## GPUImageVideoPhotoDemo ##
======================

GPUImageVideoPhotoDemo  

iOS用です。GPUImageのビデオデバイスから、任意のタイミングで写真用のイメージを取り出すデモプログラムです。  

## 概要 ##
GPUImageのビデオデバイス(GPUImageVideoCamera)のdelegate；willOutputSampleBuffer(ビデオ撮影からサンプルバッファーを得る)が出力するイメージはYUV形式であり、これをRGBに変換してUIImageデータを取り出している。  
UIImageデータだと使い勝手がよくなる。


## 必要なFramework ##
* opencv2.framework
* libGPUImage.a
* AVFoundation.framework
* CoreMedia.framework
* CoreVideo.framework
* OpenGLES.framework
* Quartz.framework
* CoreGraphics.framework
* UIKit.framework
* Foundation.framework


## 参考 ##
* GPUImage github <https://github.com/BradLarson/GPUImage>
* Installation in iOS <http://docs.opencv.org/doc/tutorials/introduction/ios_install/ios_install.html>
* Converting CVImageBufferRef YUV 420 to cv::Mat RGB and displaying it in a CALayer? <http://stackoverflow.com/questions/20276837/converting-cvimagebufferref-yuv-420-to-cvmat-rgb-and-displaying-it-in-a-calaye>
