Easy-Screen-Recorder
====================

Now easily record your iOS application video for any special purpose

1>Add files ESRViewVideoHandler.h and ESRViewVideoHandler.m file on your project directory 
  (don't forget to check "copy items into destination group's folder(if needed)" while adding into your project.
  
2>Add [ESRViewVideoHandler startScreenRecording] and [ESRViewVideoHandler stopScreenRecording] in AppDelegate's
  applicationDidBecomeActive and  applicationDidEnterBackground respectively or where ever you want.
  
  If you call those methods in applicationDidBecomeActive and applicationDidEnterBackground video recording started
  at application start and ended only when you enter into background.
  
  *It works on both real device as well as simulator.
  *Currently video is saved into Document Directory.
  *Totally AppStore safe.
