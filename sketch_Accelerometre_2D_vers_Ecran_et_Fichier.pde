//////////////////////////////////////////////////////////////////////////////////////////
/*
   Accéléromètre DE-ACCM2G de DimensionEngineering (construit autour de l'ADXL322)
   http://3615.entropie.org
   
   Compile avec Processing 3.5.3
*/
//////////////////////////////////////////////////////////////////////////////////////////

import processing.serial.*;  // Charge la bibliothèque serial.

Serial myPort;               // Création de l'objet myPort (classe Serial).
int baudrate = 9600;         // Vitesse de transfert des données (en bauds).
int valPort = 0;             // Données reçues depuis le port série.
String buffer = "";          // Un petit tampon pour récupérer la dernière valeur  
                             // mesurée sous la forme d'une chaine de caractères.
                             
// Valeurs mesurées par la carte Arduino codée sur 10 bits (entre 0 et 1023 en décimal)
int valueX = 0;
int valueY = 0;

// Etalonnage d'après des mesures effectuées sur mon capteur (tous les 10°).
int nbReleves = 19;
int[ ] degX = {-90,-80,-70,-60,-50,-40,-30,-20,-10,  0, 10, 20, 30, 40, 50, 60, 70, 80, 90};
int[ ] X    = {367,369,376,387,402,420,441,464,489,515,542,567,590,611,629,643,654,660,662};

int[ ] degY = {-90,-80,-70,-60,-50,-40,-30,-20,-10,  0, 10, 20, 30, 40, 50, 60, 70, 80, 90};
int[ ] Y    = {355,357,364,375,389,408,429,452,477,504,530,554,578,598,616,630,641,647,650};

// Pour le calcul de l'inclinaison
float degXmin;
float degXmax;
int Xmin;
int Xmax;
float degYmin;
float degYmax;
int Ymin;
int Ymax;
float angleX = 0;
float angleY = 0;

// Nombre de frames par seconde
int fps = 50; 

// Tensions
float tensionX = 0;
float tensionY = 0;

// Création d'un objet PrintWriter
PrintWriter output;

//////////////////////////////////////////////////////////////////////////////////////////

void setup()
{  
  frameRate(fps);
  size(displayWidth, displayHeight, P3D);
  fill(255, 0, 0, 200);

  println("Ports séries disponibles :");
  println(Serial.list());
 
  // Sur mon ordinateur sous Ubuntu ou Debian, la carte Arduino est connectée au port 
  // /dev/ttyUSB0, le premier dans la liste, d'où le 0 dans Serial.list()[0].  
  // Sur mon ordinateur sous Windows, la carte Arduino est connectée au port COM3,
  // le deuxième dans la liste, d'où le 1 dans Serial.list()[1]. 
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, baudrate);
  
  PFont police = loadFont("CourierNewPS-BoldMT-48.vlw");
  textFont(police, 48); 
  
  // Créé un fichier données.txt dans le répertoire du sketch
  output = createWriter("données.txt");
}

//////////////////////////////////////////////////////////////////////////////////////////

void draw()
{
  background(0);
  stroke(255);
  
  while (myPort.available() > 0) {
    // Pour transmettre la valeur mesurée codée sur 10 bits (2^10 = 1024),
    // soit un nombre compris entre 0 et 1023,
    // valPort prend successivement des valeurs entre 48 et 57,
    // ce qui correspond en code ASCII aux caractères 0 à 9.
    // Quand la valeur à transmettre (0 à 1023) l'est, valPort prend les valeurs 
    // 13 (retour chariot en code ASCII), puis 10 (saut à la ligne en code ASCII).
    valPort = myPort.read();
    serialEvent(valPort);
  }
  
  // Enregistre la température mesurée dans le fichier données.txt. L'instant où
  // la mesure a été effectuée est également conservé. Ce fichier pourra être importé 
  // dans un tableur (le point virgule est choisi comme séparateur de données).
  if (valueX != 0) { 
    output.println(nf(millis(), 2, 0) + ";"
                 + nf(valueX, 0, 0) + ";" 
                 + nf(valueY, 0, 0));   // nf : formate l'écriture d'un nombre
  }
  
  // Titre   
    textAlign(CENTER, CENTER);
    text("L'accéléromètre 2D", width/2, 48); 
    
  // X
  if (valueX != 0) {
    tensionX = 5 * valueX / 1023.0;
    textAlign(CENTER, CENTER);
    text("X : " + nf(tensionX, 0, 2) + " V => " + valueX, width/2, height/2 -36); 
  }
                                                                    
  // Y
  if (valueY != 0) {
    tensionY = 5 * valueY / 1023.0; 
    textAlign(CENTER, CENTER);
    text("Y : " + nf(tensionY, 0, 2) + " V => " + valueY, width/2, height/2 +36); 
  } 
 
  // angleX
  if (valueX < X[0]) angleX = -90;  
  for (int i = 0; i < nbReleves-1; i++) {
    if (valueX >= X[i] && valueX < X[i+1]) {
      degXmin = degX[i];
      degXmax = degX[i+1];
      Xmin = X[i];
      Xmax = X[i+1];
      // fonction affine du type y = ax + b
      float a = (degXmax - degXmin) / (Xmax - Xmin);
      float b = degXmin - Xmin * (degXmax - degXmin) / (Xmax - Xmin);
      angleX = a * valueX + b;
    }
  } 
  if (valueX >= X[nbReleves-1]) angleX = 90;  

  // angleY
  if (valueY < Y[0]) angleY = -90; 
  for (int i = 0; i < nbReleves-1; i++) {
    if (valueY >= Y[i] && valueY < Y[i+1]) {
      degYmin = degY[i];
      degYmax = degY[i+1];
      Ymin = Y[i];
      Ymax = Y[i+1];
      // fonction affine du type y = ax + b
      float a = (degYmax - degYmin) / (Ymax - Ymin);
      float b = degYmin - Ymin * (degYmax - degYmin) / (Ymax - Ymin);
      angleY = a * valueY + b;
    }
  }
  if (valueY >= Y[nbReleves-1]) angleY = 90; 
 
  // Affichage du parallélépipède
  translate(width / 2, height / 2, 0);
  rotateX(radians(angleX));
  rotateZ(radians(-angleY));
  box(560,208,400);
}

//////////////////////////////////////////////////////////////////////////////////////////

void serialEvent(int serial)         // Méthode de la classe Serial.
{
  print("valPort : " + valPort);     // Pour information dans la console.
  if (serial != 10) {                // 10 <=> saut à la ligne en code ASCII.
    buffer += char(serial);          // Store all the characters on the line.   
  } 
  else {
    // The end of each line is marked by two characters, a carriage return (13) 
    // and a newline (10). We're here because we've gotten a newline,
    // but we still need to strip off the carriage return.
    
    // Le premier caractère nous indique à quelle grandeur est associée la valeur lue.
    char lettre = buffer.charAt(0);
    // On supprime ce caractère de la chaine en prenant la sous-chaine qui commence 
    // au deuxième caractère de la chaine (1).
    buffer = buffer.substring(1);
    // On prend la sous-chaine qui va du premier caractère (0) à l'avant dernier.
    buffer = buffer.substring(0, buffer.length()-1);
    
    // Parse the String into an integer (analog inputs go from 0 to 1023).   
    if (lettre == 'X')
      valueX = Integer.parseInt(buffer);
    if (lettre == 'Y')
      valueY = Integer.parseInt(buffer);
    
    // Clear the value of "buffer"  
    buffer = "";
  }  
  println(" => buffer : " + buffer);  // Pour information dans la console.
}

//////////////////////////////////////////////////////////////////////////////////////////

void keyPressed() {
  if (key == ESC) {
    output.flush();  // Writes the remaining data to the file
    output.close();  // Finishes the file
    exit();          // Stops the program
  }
}

//////////////////////////////////////////////////////////////////////////////////////////
