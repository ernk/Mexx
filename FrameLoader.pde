class FrameLoader {
  ArrayList<PImage> allFrames;

  FrameLoader() {
    allFrames = new ArrayList<PImage>();
  }
  
  void loadFrames(String path) {
    println("\nListing info about all files in a directory: " + path);
    File[] files = listFiles(path);
    for (int i = 0; i < files.length; i++) {
      File f = files[i];    
      allFrames.add(loadImage(f.getAbsolutePath()));
//      println("Name: " + f.getName());
//      println("Is directory: " + f.isDirectory());
//      println("Size: " + f.length());
//      String lastModified = new Date(f.lastModified()).toString();
//      println("Last Modified: " + lastModified);
//      println("-----------------------");
    }
  }

  // This function returns all the files in a directory as an array of File objects
  // This is useful if you want more info about the file
  File[] listFiles(String dir) {
    File file = new File(dir);
    if (file.isDirectory()) {
      File[] files = file.listFiles();
      return files;
    } 
    else {
      // If it's not a directory
      return null;
    }
  }
}

