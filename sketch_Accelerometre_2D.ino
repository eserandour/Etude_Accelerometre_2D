//////////////////////////////////////////////////////////////////////////////////////////
/*
   Accéléromètre DE-ACCM2G de DimensionEngineering (construit autour de l'ADXL322)
   http://3615.entropie.org
   Adapté de Smoothing (http://arduino.cc/en/Tutorial/Smoothing) 
*/
//////////////////////////////////////////////////////////////////////////////////////////

// NBPINS indique le nombre d'entrées analogiques utilisées.
// Dans les accolades, indiquer les numéros des entrées analogiques utilisées (de 0 à 5).
#define NBPINS 3                    // 2 entrées sont utilisées : une pour X, une pour Y.
int aPin[NBPINS] = {8, 9, 10};

// A chaque entrée, j'associe une lettre.
// Si FIRSTLETTER = 65 (A en code ASCII),
// alors A sera associée à l'entrée aPin[0], B à l'entrée aPin[1], etc.
#define FIRSTLETTER 88              // 88 correspond à X en code ASCII.

// Pour effectuer un lissage sur les NBREADINGS dernières valeurs lues.
#define NBREADINGS 10
int readingsPin[NBPINS][NBREADINGS];            // Tableau à double entrée
int index[NBPINS];
int total[NBPINS];
int moyenne[NBPINS];

void setup() {
  Serial.begin(9600);                           // Transfert des données à 9600 bauds.
   for (int i = 0; i < NBPINS; i++) {
    for (int j = 0; j < NBREADINGS; j++) {
      readingsPin[i][j] = 0;                    // Initialisation à 0.
    }
  }
}

void loop() {   
  for (int i = 0; i < NBPINS; i++) {                    // BOUCLE FOR
    total[i] -= readingsPin[i][index[i]];              // subtract the last reading
    readingsPin[i][index[i]] = analogRead(aPin[i]);   // read from the sensor
    total[i] += readingsPin[i][index[i]];            // add the reading to the total
    index[i]++;                                     // advance to the next index
    if (index[i] >= NBREADINGS)                    // if we're at the end of the array...
      index[i] = 0;                               // ...wrap around to the beginning
    moyenne[i] = total[i] / NBREADINGS;          // calculate the average                                          
  }                                             // FIN BOUCLE FOR

  for (int i = 0; i < NBPINS; i++) {          // BOUCLE FOR
    Serial.print(char(FIRSTLETTER + i));     // print as an ASCII-encoded decimal
    Serial.println(moyenne[i]);             // send it to the computer (as ASCII digits)
  }                                        // FIN BOUCLE FOR
    
  delay(20);                             // Laisse du temps pour le transfert des données.
}

//////////////////////////////////////////////////////////////////////////////////////////
