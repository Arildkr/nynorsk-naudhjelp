import 'dart:convert';
import 'dart:io';

void main() {
  final List<Map<String, dynamic>> questions = [];
  int idCounter = 100;

  String nextId(String prefix) => '${prefix}_${idCounter++}';

  // --- SUBSTANTIV ---
  final Map<String, String> hokjonn = {
    'jente': 'ei', 'bok': 'ei', 'sol': 'ei', 'tid': 'ei', 'seng': 'ei',
    'klokke': 'ei', 'dør': 'ei', 'øy': 'ei', 'hytte': 'ei', 'bygd': 'ei',
    'elv': 'ei', 'bru': 'ei', 'vik': 'ei', 'strand': 'ei', 'sjel': 'ei', 
    'verd': 'ei', 'sanning': 'ei', 'tru': 'ei', 'lov': 'ei', 'høne': 'ei',
    'ku': 'ei', 'stjerne': 'ei', 'flaske': 'ei', 'kasse': 'ei', 'jakke': 'ei',
    'bukse': 'ei', 'vogn': 'ei', 'vugge': 'ei', 'bokhylle': 'ei', 'kake': 'ei',
    'stove': 'ei', 'pipe': 'ei', 'avis': 'ei', 'saks': 'ei', 'lue': 'ei',
    'mus': 'ei', 'tann': 'ei', 'leppe': 'ei', 'maske': 'ei', 'ferje': 'ei',
    'glede': 'ei', 'sorg': 'ei', 'natt': 'ei', 'makt': 'ei', 'kraft': 'ei'
  };
  final Map<String, String> hankjonn = {
    'gut': 'ein', 'bil': 'ein', 'dag': 'ein', 'veg': 'ein', 'båt': 'ein',
    'skule': 'ein', 'lærar': 'ein', 'stol': 'ein', 'vegg': 'ein', 'hund': 'ein',
    'katt': 'ein', 'fisk': 'ein', 'hest': 'ein', 'hage': 'ein', 'skog': 'ein',
    'draume': 'ein', 'tanke': 'ein', 'song': 'ein', 'lyd': 'ein', 'far': 'ein',
    'bror': 'ein', 'son': 'ein', 'onkel': 'ein', 'bestefar': 'ein', 'ven': 'ein',
    'fjelltopp': 'ein', 'stein': 'ein', 'bekk': 'ein', 'fot': 'ein', 'arm': 'ein',
    'rygg': 'ein', 'mage': 'ein', 'hals': 'ein', 'munn': 'ein', 'banan': 'ein',
    'appelsin': 'ein', 'leik': 'ein', 'draum': 'ein', 'sjø': 'ein', 'vind': 'ein',
    'storm': 'ein', 'snø': 'ein', 'regnboge': 'ein', 'frosk': 'ein', 'fugl': 'ein'
  };
  final Map<String, String> inkjekjonn = {
    'hus': 'eit', 'fjell': 'eit', 'eple': 'eit', 'tre': 'eit', 'dyr': 'eit',
    'bord': 'eit', 'skap': 'eit', 'glas': 'eit', 'bilete': 'eit', 'land': 'eit',
    'vatn': 'eit', 'hav': 'eit', 'ord': 'eit', 'språk': 'eit', 'menneske': 'eit',
    'blad': 'eit', 'hår': 'eit', 'auga': 'eit', 'øyre': 'eit', 'problem': 'eit',
    'barn': 'eit', 'sysken': 'eit', 'tak': 'eit', 'golv': 'eit', 'vindauge': 'eit',
    'teppe': 'eit', 'skjørt': 'eit', 'belte': 'eit', 'slips': 'eit', 'smykke': 'eit',
    'skjerf': 'eit', 'tog': 'eit', 'fly': 'eit', 'skip': 'eit', 'kort': 'eit',
    'brev': 'eit', 'merke': 'eit', 'namn': 'eit', 'svar': 'eit', 'spørsmål': 'eit',
    'skritt': 'eit', 'smil': 'eit', 'kinn': 'eit', 'spel': 'eit', 'badekar': 'eit'
  };

  void addGenderSwipe(Map<String, String> words, String correctArt, String baseExp) {
    for (var word in words.keys) {
      questions.add({
        "id": nextId('sub'),
        "type": "SWIPE_CHOICE",
        "category": "substantiv_kjonn",
        "difficulty": 1,
        "text": "Kva kjønn er '$word'?",
        "options": ["Hankjønn (ein)", "Hokjønn (ei)", "Inkjekjønn (eit)"],
        "correctAnswer": correctArt == 'ein' ? "Hankjønn (ein)" : correctArt == 'ei' ? "Hokjønn (ei)" : "Inkjekjønn (eit)",
        "explanation": "$baseExp: $correctArt $word."
      });
    }
  }

  addGenderSwipe(hokjonn, 'ei', "Eit klassisk hokjønnsord, hugsar me");
  addGenderSwipe(hankjonn, 'ein', "Slik kan me lære at dette er eit hankjønnsord");
  addGenderSwipe(inkjekjonn, 'eit', "Både på bokmål og nynorsk fell dette i inkjekjønn");

  // --- SUBSTANTIV BØYING ---
  questions.addAll([
    {
      "id": nextId('sub_m'), "type": "FILL_IN", "category": "substantiv_boying", "difficulty": 2,
      "text": "Bøy ordet: Ein gut - guten - fleire gutar - alle ___.",
      "correctAnswer": "gutane", "explanation": "Hankjønnsord får som regel -ane i bestemt form flertall."
    },
    {
      "id": nextId('sub_m'), "type": "FILL_IN", "category": "substantiv_boying", "difficulty": 2,
      "text": "Bøy ordet: Ei jente - jenta - fleire jenter - alle ___.",
      "correctAnswer": "jentene", "explanation": "Hokjønnsord som endar på -e får som regel -ene i bestemt form flertall."
    },
    {
      "id": nextId('sub_m'), "type": "FILL_IN", "category": "substantiv_boying", "difficulty": 3,
      "text": "Bøy ordet: Eit hus - huset - fleire hus - alle ___.",
      "correctAnswer": "husa", "explanation": "Einstava inkjekjønnsord får inga ending i ubestemt flertall, og alltid -a i bestemt flertall (alle husa)."
    },
    {
      "id": nextId('sub_m'), "type": "FILL_IN", "category": "substantiv_boying", "difficulty": 3,
      "text": "Bøy ordet: Eit eple - eplet - fleire eple - alle ___.",
      "correctAnswer": "epla", "explanation": "Alle inkjekjønnsord (sjølv tostava) får endinga -a i bestemt form flertall."
    },
  ]);

  // --- VERB (A-verb) ---
  final List<String> aVerb = ['kaste', 'hoppe', 'danse', 'fiske', 'sykle', 'bade', 'snakke', 'hugse', 'hate', 'elske', 'klatre', 'vaske', 'sparke', 'male', 'teikne', 'smile', 'puste', 'kviskre', 'lytte', 'rope', 'leike', 'svara', 'rydde', 'dusje', 'hente'];
  for (var v in aVerb) {
    String base = v.endsWith('e') ? v.substring(0, v.length - 1) : v;
    questions.add({
      "id": nextId('verb_a'), "type": "MULTIPLE_CHOICE", "category": "verb_boying", "difficulty": 1,
      "text": "Kva er preteritum (fortid) av å $v?",
      "options": ["${base}a", "${base}et", "${base}te", v],
      "correctAnswer": "${base}a",
      "explanation": "Dette er eit a-verb. Det får endinga -a i preteritum (å $v - ${v}ar - ${base}a - har ${base}a)."
    });
  }

  // --- VERB (E-verb) ---
  final List<List<String>> eVerb = [
    ['kjøpe', 'kjøper', 'kjøpte'],
    ['lyse', 'lyser', 'lyste'],
    ['høyre', 'høyrer', 'høyrde'],
    ['køyre', 'køyrer', 'køyrde'],
    ['dømme', 'dømmer', 'dømde'],
    ['gløyme', 'gløymer', 'gløymde'],
    ['lære', 'lærer', 'lærte'],
    ['leve', 'lever', 'levde'],
    ['kjenne', 'kjenner', 'kjende'],
    ['drøyme', 'drøymer', 'drøymde'],
    ['vise', 'viser', 'viste'],
    ['reise', 'reiser', 'reiste'],
    ['bygge', 'bygger', 'bygde'],
    ['sende', 'sender', 'sende'],
  ];
  for (var v in eVerb) {
    questions.add({
      "id": nextId('verb_e'), "type": "MULTIPLE_CHOICE", "category": "verb_boying", "difficulty": 2,
      "text": "Kva er preteritum (fortid) av å ${v[0]}?",
      "options": [v[2], "${v[0]}a", "${v[0]}et", "${v[0]}"],
      "correctAnswer": v[2],
      "explanation": "Dette er eit verb som fell under e-verb eller j-verb klassen med eiga ending. (å ${v[0]} - ${v[1]} - ${v[2]})."
    });
  }

  // --- ORDERFORRÅD ---
  final Map<String, List<String>> ordf = {
    'kvifor': ['hvorfor', 'hvordan', 'hvilken', 'når'],
    'korleis': ['hvordan', 'hvorfor', 'kanskje', 'aldri'],
    'kven': ['hvem', 'kan', 'hva', 'når'],
    'kvar': ['hvor', 'hver', 'hvordan', 'kveles'],
    'kva': ['hva', 'hvor', 'hvordan', 'kaos'],
    'alltid': ['alltid', 'aldri', 'kanskje', 'ofte'],
    'særskild': ['spesiell / spesielt', 'rask', 'selvfølgelig', 'aldri'],
    'vonleg': ['forhåpentligvis', 'vanligvis', 'vondt', 'kanskje'],
    'røyndom': ['virkelighet', 'røyk', 'kunnskap', 'drøm'],
    'løyndom': ['hemmelighet', 'løgn', 'latter', 'rom'],
    'kjærleik': ['kjærlighet', 'kjæreste', 'vennskap', 'hat'],
    'byrje': ['begynne', 'bygge', 'bryte', 'brøle'],
    'høve': ['anledning/mulighet', 'hode', 'bakke', 'hatt'],
    'av di': ['fordi', 'hvis ikke', 'aldri', 'kanskje'],
    'medan': ['mens', 'mellom', 'midt i', 'mat'],
    'òg': ['også', 'å', 'og', 'aldri'],
    'eigentleg': ['egentlig', 'egen', 'selv', 'alltid'],
    'skilnad': ['forskjell', 'skilsmisse', 'skilt', 'likhet'],
    'likskap': ['likhet', 'skap', 'forskjell', 'lykke'],
  };

  for (var kv in ordf.entries) {
    questions.add({
      "id": nextId('ord'), "type": "MULTIPLE_CHOICE", "category": "ordforrad", "difficulty": 2,
      "text": "Kva betyr det nynorske ordet '${kv.key}'?",
      "options": [kv.value[0], kv.value[1], kv.value[2], kv.value[3]],
      "correctAnswer": kv.value[0],
      "explanation": "'${kv.key}' oversettast primært til '${kv.value[0]}' på bokmål."
    });
  }

  // --- PRONOMEN (Objektsform) ---
  final Map<String, String> pron = {
    'Heiar du på ___ (eg)?': 'meg',
    'Eg ser ___ (du).': 'deg',
    'Snakkar ho til ___ (han)?': 'han',
    'Me likar ___ (ho).': 'henne',
    'Likar de ___ (dei)?': 'dei',
    'Gi boka til ___ (vi)!': 'oss',
    'Vi gler ___ (vi).': 'oss',
    'Kven ropte på ___ (ho)?': 'henne',
    'Vil du ha ___ (han)?': 'han',
  };
  pron.forEach((sentence, ans) {
    questions.add({
      "id": nextId('pron'), "type": "FILL_IN", "category": "pronomen", "difficulty": 1,
      "text": sentence,
      "correctAnswer": ans,
      "explanation": "Dette er objektsforma av pronomenet på nynorsk."
    });
  });

  // --- EIENDOMSORD PLASSERING ---
  final eieSentences = [
    ["Boka mi er fin.", "Min bok er fin.", "Mi bok er fin.", "Boka min er fin."],
    ["Huset mitt er raudt", "Mitt hus er raudt", "Huset min er raud", "Husa mi er raud"],
    ["Bøkene mine er tunge", "Mine bøker er tunge", "Mine bøkene er tunge", "Bøkene min er tung"],
    ["Søstera di er grei", "Di søster er grei", "Søstera din er grei", "Søsteren di er grei"],
    ["Rommet hans er reint", "Hans rom er reint", "Hans rommet er reint", "Rommet han er reint"],
  ];
  for (var opts in eieSentences) {
    questions.add({
      "id": nextId('eie'), "type": "MULTIPLE_CHOICE", "category": "eiendomsord", "difficulty": 2,
      "text": "Kva er den mest naturlege og korrekte måten å seie dette på nynorsk?",
      "options": [opts[0], opts[1], opts[2], opts[3]],
      "correctAnswer": opts[0],
      "explanation": "På nynorsk står eigedomsordet normalt etter substantivet, og substantivet skal ha bestemt form (${opts[0]})."
    });
  }

  final jsonOutput = {"questions": questions};
  
  final file = File('assets/data/questions.json');
  file.writeAsStringSync(jsonEncode(jsonOutput));
  
  print('Genererte \${questions.length} spørsmål i spørsmålsbanken!');
}
