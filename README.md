GPUImageVideoPhotoDemo
======================

GPUImageVideoPhotoDemo

GPUImageのビデオデバイスのフィルタ出力から、写真用のイメージを取り出デモプログラムです。

GPUImageのビデオデバイスのdelegate；willOutputSampleBufferが出力するイメージはYUV形式であり、これをRGBに変換してUIImageデータを取り出している。
