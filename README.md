# projet janvier horloge (pic18f25k40)

## auteur

louis mingot

## description

ce projet consiste à réaliser une horloge numérique à base d’un microcontrôleur pic18f25k40, programmée entièrement en assembleur.

l’horloge utilise une rtc externe (mcp7940) communiquant via le bus i2c et affiche l’heure à l’aide de leds vertes et de leds rgb adressables.

le système permet l’affichage et la modification de l’heure à l’aide de boutons, avec une synchronisation matérielle fiable assurée par la rtc.

## fonctionnalités principales

- communication i2c maître avec la rtc mcp7940
- lecture et écriture des heures et minutes
- conversion bcd ↔ décimal
- affichage des minutes modulo 5 sur leds vertes
- affichage circulaire sur 12 leds rgb :
  - heures en rouge
  - minutes en bleu
  - superposition heures + minutes en violet
- modification de l’heure via boutons poussoirs
- mode édition empêchant la rtc d’écraser les valeurs modifiées
- temporisations précises pour leds rgb (bit banging)

## matériel utilisé

- microcontrôleur pic18f25k40
- rtc mcp7940
- quartz externe pour la rtc
- 12 leds rgb adressables (type ws2812 ou équivalent)
- 4 leds vertes
- 4 boutons poussoirs
- résistances de pull-up pour sda et scl

## brochage principal

### i2c (rtc)
- rc3 : scl
- rc4 : sda

### leds vertes
- ra0 à ra3

### leds rgb
- rc1 : ligne data

### boutons
- rb1 : minutes -
- rb2 : heures -
- rb3 : heures +
- rb4 : minutes +

## organisation logicielle

le programme est structuré en plusieurs parties :

- configuration :
  - oscillateur interne (64 mhz)
  - ports i/o
  - module i2c
- rtc :
  - initialisation
  - lecture de l’heure
  - écriture des heures et minutes
- i2c :
  - routines send et receive en polling
- affichage :
  - leds vertes (minutes % 5)
  - leds rgb (heures / minutes)
- boutons :
  - détection
  - gestion des incréments et décrments
- utilitaires :
  - conversions bcd / décimal
  - calculs modulo et divisions
- temporisations :
  - timers (0.1s, 1s, etc.)
  - délais précis par nop pour les leds rgb

## principe d’affichage

- l’horloge est divisée en 12 positions (0 à 11)
- hourscounter ∈ [0..11] correspond à l’index rouge
- minutescounter ∈ [0..59]
  - minutesindex = minutescounter / 5 → index bleu
- si les deux index coïncident :
  - la led rgb devient violette
- les leds vertes indiquent les minutes modulo 5

## gestion des boutons

lorsqu’un bouton est pressé :

- activation du mode édition
- blocage temporaire de la lecture rtc
- mise à jour des compteurs internes
- écriture dans la rtc
- mise à jour immédiate de l’affichage
- temporisation anti-rebond

## choix techniques

- assembleur pic18 pour un contrôle précis du matériel
- i2c en polling pour la simplicité
- génération des signaux rgb par nop pour une précision maximale
- format interne des heures : 0..11 (adapté à l’affichage circulaire)
- rtc utilisée comme référence de temps

## limites et améliorations possibles

- pas d’affichage des secondes
- pas de gestion am/pm
- pas de mode 24h
- amélioration possible de l’anti-rebond
- ajout d’interruptions pour une meilleure réactivité

## compilation et programmation

- ide : mplab x
- assembleur : mpasm
- cible : pic18f25k40
- programmateur : pickit

## conclusion

ce projet met en œuvre les notions fondamentales de l’embarqué :

- communication i2c
- programmation assembleur bas niveau
- gestion du temps réel
- affichage led complexe
- interaction utilisateur

il constitue une base solide pour comprendre le fonctionnement interne d’une horloge numérique sur microcontrôleur pic.
