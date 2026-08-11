#import "@preview/cetz:0.5.2": canvas, coordinate, draw
#import "@preview/cetz-plot:0.1.4": plot

/// Fait tourner le point (x, y) de `angle` autour du centre (cx, cy).
///
/// - cx (float, int): abscisse du centre de rotation
/// - cy (float, int): ordonnée du centre de rotation
/// - x (float, int): abscisse du point à faire tourner
/// - y (float, int): ordonnée du point à faire tourner
/// - angle (angle): angle de rotation
/// -> array
#let rotate-point(
  /// Abscisse du centre de rotation.
  /// -> float | int
  cx,

  /// Ordonnée du centre de rotation.
  /// -> float | int
  cy,

  /// Abscisse du point à faire tourner.
  /// -> float | int
  x,

  /// Ordonnée du point à faire tourner.
  /// -> float | int
  y,
  
  /// Angle de rotation.
  /// -> angle
  angle,
) = {
  let dx = x - cx
  let dy = y - cy
  let c = calc.cos(angle)
  let s = calc.sin(angle)
  (cx + dx * c - dy * s, cy + dx * s + dy * c)
}

/// Dessine la "marque" d'un point à une position DÉJÀ EN COORDONNÉES DU
/// CANVAS (x, y en cm). Choix de forme partagé entre point-marker (dessine
/// en unités de données, dans plot.annotate) et anchored-point
/// (dessine en cm, hors du plot). Ne pas appeler directement en temps normal.
///
/// - x (float, int): abscisse du point, en unités canvas
/// - y (float, int): ordonnée du point, en unités canvas
/// - symbol (str): "o" (rond), "x" (croix), "+" (plus), "square" (carré), "triangle", "diamond" (losange)
/// - size (float, int): demi-taille du symbole, dans la même unité que x, y
/// - fill (color): couleur de remplissage (formes fermées) ou du trait ("+"/"x")
/// - stroke (none, stroke, color): contour des formes fermées (none = pas de contour, juste fill)
/// - angle (angle): orientation (pertinent pour "square", "triangle", "diamond", "+", "x" — sans effet sur "o")
/// -> content
#let draw-mark-shape(
  /// Abscisse du point, en unités canvas.
  /// -> float | int
  x,

  /// Ordonnée du point, en unités canvas.
  /// -> float | int
  y,

  /// "o" (rond), "x" (croix), "+" (plus), "square" (carré), "triangle", "diamond" (losange).
  /// -> string
  symbol: "o",

  /// Demi-taille du symbole, dans la même unité que x, y.
  /// -> float | int
  size: 0.06,

  /// Couleur de remplissage (formes fermées) ou du trait ("+"/"x").
  /// -> color
  fill: red,

  /// Contour des formes fermées (none = pas de contour, juste fill).
  /// -> none | stroke | color
  stroke: none,

  /// Orientation (pertinent pour "square", "triangle", "diamond", "+", "x" — sans effet sur "o").
  /// -> angle
  angle: 0deg,
) = {
  import draw: circle, line

  if symbol == "o" or symbol == "circle" {
    circle((x, y), radius: size, fill: fill, stroke: stroke)
  } else if symbol == "square" {
    let pts = (
      ((-1, -1), (1, -1), (1, 1), (-1, 1)).map(((dx, dy)) => rotate-point(x, y, x + dx * size, y + dy * size, angle))
    )
    line(..pts, close: true, fill: fill, stroke: stroke)
  } else if symbol == "diamond" {
    let pts = (
      ((0, -1), (1, 0), (0, 1), (-1, 0)).map(((dx, dy)) => rotate-point(x, y, x + dx * size, y + dy * size, angle))
    )
    line(..pts, close: true, fill: fill, stroke: stroke)
  } else if symbol == "triangle" {
    let pts = (
      ((0, 1), (-0.87, -0.5), (0.87, -0.5)).map(((dx, dy)) => rotate-point(x, y, x + dx * size, y + dy * size, angle))
    )
    line(..pts, close: true, fill: fill, stroke: stroke)
  } else if symbol == "+" {
    let s = if stroke == none { 1pt } else { stroke }
    line(
      rotate-point(x, y, x - size, y, angle),
      rotate-point(x, y, x + size, y, angle),
      stroke: s,
    )
    line(
      rotate-point(x, y, x, y - size, angle),
      rotate-point(x, y, x, y + size, angle),
      stroke: s,
    )
  } else if symbol == "x" {
    let s = if stroke == none { 1pt } else { stroke }
    line(
      rotate-point(x, y, x - size, y - size, angle),
      rotate-point(x, y, x + size, y + size, angle),
      stroke: s,
    )
    line(
      rotate-point(x, y, x - size, y + size, angle),
      rotate-point(x, y, x + size, y - size, angle),
      stroke: s,
    )
  } else {
    panic("marqueur : symbole inconnu '" + symbol + "'")
  }
}

/// Marque un point isolé (x, y) EN UNITÉS DE DONNÉES — à utiliser DANS
/// plot.annotate (cetz-plot gère alors la mise à l'échelle lui-même).
/// Même vocabulaire de formes que plot.add (mark:), mais sans son bug du
/// point unique. Voir draw-mark-shape pour le détail des paramètres.
///
/// - x (float, int): abscisse du point, en unités de données
/// - y (float, int): ordonnée du point, en unités de données
/// - symbol (str): "o", "x", "+", "square", "triangle", "diamond"
/// - size (float, int): demi-taille du symbole, en unités de données
/// - fill (color): couleur de remplissage ou du trait
/// - stroke (none, stroke, color): contour (none = pas de contour, juste fill)
/// - angle (angle): orientation du symbole
/// -> content
#let point-marker(
  /// Abscisse du point, en unités de données.
  /// -> float | int
  x,
  
  /// Ordonnée du point, en unités de données.
  /// -> float | int
  y,

  /// "o", "x", "+", "square", "triangle", "diamond".
  /// -> string
  symbol: "o",

  /// Demi-taille du symbole, en unités de données.
  /// -> float | int
  size: 0.06,

  /// Couleur de remplissage ou du trait.
  /// -> color
  fill: red,

  /// Contour (none = pas de contour, juste fill).
  /// -> none | stroke | color
  stroke: none,

  /// Orientation du symbole.
  /// -> angle
  angle: 0deg,
) = {
  draw-mark-shape(x, y, symbol: symbol, size: size, fill: fill, stroke: stroke, angle: angle)
}


/// Nuage de points : trace un marqueur à chacun des points de `points`.
/// À utiliser comme plot.add(...), DANS plot.plot(...) — c'est-à-dire
/// directement dans le `body` de newFig — les coordonnées restent en
/// unités de DONNÉES, cetz-plot gère la mise à l'échelle lui-même.
/// Enveloppe légère autour de plot.add(...), avec un vocabulaire de
/// marqueur plus accessible (mark-fill/mark-stroke au lieu d'un
/// dictionnaire mark-style brut).
///
/// - points (array): liste de couples de points (x, y), en unités de données
/// - mark (str): forme du marqueur ("o", "x", "+", "square", "triangle", "diamond"...), transmise à plot.add(mark:)
/// - mark-fill (color): couleur de remplissage du marqueur
/// - mark-stroke (none, stroke, color): contour du marqueur (none = pas de contour)
/// - mark-size (float, int): taille du marqueur, transmise à plot.add(mark-size:)
///
/// ```example
/// #newFig(x-min : 0, x-max:8, y-min: 0, y-max: 5,
///   {
///     scatter(
///       ((1, 4.8), (2, 3.8), (4, 3), (6, 1.7), (7, 1.3)),
///       mark: "x",
///       mark-stroke: blue,
///       mark-size: 0.2,
///     )
///   },
/// )
/// ```
///
/// -> array
#let scatter(
  /// Liste de couples de points (x, y), en unités de données.
  /// -> array
  points,
  
  /// Forme du marqueur ("o", "x", "+", "square", "triangle", "diamond"...), transmise à plot.add(mark:).
  /// -> string
  mark: "o",
  
  /// Couleur de remplissage du marqueur.
  /// -> color
  mark-fill: black,
  
  /// Contour du marqueur (none = pas de contour).
  /// -> none | stroke | color
  mark-stroke: 1pt + black,
  
  /// Taille du marqueur, transmise à plot.add(mark-size:).
  /// -> float | int
  mark-size: 0.1,
) = {
  plot.add(
    points,
    style: (stroke: none),
    mark: mark,
    mark-style: (fill: mark-fill, stroke: mark-stroke),
    mark-size: mark-size,
  )
}




/// Facteurs d'échelle (unités canvas par unité de donnée) d'un plot dont
/// on connaît la taille physique et le domaine (fixe) des deux axes. Sert
/// à convertir une pente réelle en pente visuelle à l'écran.
///
/// - size (array): taille physique du plot (largeur, hauteur), en cm
/// - x-domain (array): domaine (x-min, x-max) de l'axe des abscisses
/// - y-domain (array): domaine (y-min, y-max) de l'axe des ordonnées
/// -> dictionary
#let plot-scale(
  /// Taille physique du plot (largeur, hauteur), en cm.
  /// -> array
  size,

  /// Domaine (x-min, x-max) de l'axe des abscisses.
  /// -> array
  x-domain,

  /// Domaine (y-min, y-max) de l'axe des ordonnées.
  /// -> array
  y-domain,
) = {
  let (w, h) = size
  let (xmin, xmax) = x-domain
  let (ymin, ymax) = y-domain
  (sx: w / (xmax - xmin), sy: h / (ymax - ymin))
}

/// Résout `origine` en position CANVAS (cm) : soit une ancre existante
/// ("plot.<nom>"), soit des coordonnées (x, y) en unités du repère
/// (O ; i, j) — auquel cas on part de l'ancre "plot.O" et on applique
/// sx, sy. Utilisé par anchored-basis-vectors, anchored-point et
/// anchored-derivative-arrow ; pas destiné à être appelé directement.
///
/// - ctx (dictionary): contexte cetz courant (fourni par get-ctx)
/// - origine (str, array): ancre "plot.<nom>", ou (x, y) en unités de données
/// - sx (float, int): facteur d'échelle en x (cm par unité de donnée)
/// - sy (float, int): facteur d'échelle en y (cm par unité de donnée)
/// -> array
#let resolve-origine(
  /// Contexte cetz courant (fourni par get-ctx).
  /// -> dictionary
  ctx,

  /// Ancre "plot.<nom>", ou (x, y) en unités de données.
  /// -> string | array
  origine,

  /// Facteur d'échelle en x (cm par unité de donnée).
  /// -> float | int
  sx,

  /// Facteur d'échelle en y (cm par unité de donnée).
  /// -> float | int
  sy,
) = {
  if type(origine) == str {
    coordinate.resolve(ctx, origine)
  } else {
    let (ctx, o) = coordinate.resolve(ctx, "plot.O")
    let (ox, oy, ..) = o
    let (dx, dy) = origine
    (ctx, (ox + dx * sx, oy + dy * sy))
  }
}


/// Trace une ligne brisée (segments successifs) entre plusieurs points du
/// repère (O ; i, j) — chaque point est une ancre "plot.<nom>" ou des
/// coordonnées (x, y) en unités de données, comme pour resolve-origine.
/// Les points sont convertis en coordonnées canvas AVANT d'être reliés,
/// donc le trait reste rectiligne à l'écran même dans un repère
/// anisotrope (contrairement à une ligne tracée en unités de données à
/// l'intérieur du plot). À appeler EN DEHORS de plot.plot(...). Récupère
/// automatiquement sx, sy (calculés par newFig) : rien à refournir.
///
/// - points (str | array): ancres "plot.<nom>" et/ou coordonnées (x, y), au moins deux
/// - stroke (stroke): trait de la ligne
/// - mark (none | dictionary): pointes de flèche aux extrémités (voir line(mark:))
///
/// ```example
/// #newFig(
///   extra: (sx, sy) => {
///     import draw: *
///     // pointillés (0 ; f) -- (x ; f) -- (x ; 0)
///     anchored-lines((0, 1), (1, 1), (1, 0), stroke: (thickness: 0.75pt, dash: "dashed", paint: red))
///   },
///   { plot.add(domain: (-2, 2), x => calc.pow(x, 2), style: (stroke: blue + 0.5pt), samples: 50) },
/// )
/// ```
///
/// -> content
#let anchored-lines(
  /// Ancres "plot.<nom>" et/ou coordonnées (x, y), au moins deux.
  /// -> string | array
  ..points,

  /// Trait de la ligne.
  /// -> stroke
  stroke: black + 1pt,

  /// Pointes de flèche aux extrémités (voir line(mark:)).
  /// -> none | dictionary
  mark: none,
) = {
  import draw: get-ctx, line
  
  let pts = points.pos()
  
  get-ctx(ctx => {
    let (sx, sy) = ctx.at("helper-scale", default: (1, 1))
    let ctx = ctx
    let canvas-pts = ()
    for p in pts {
      let (new-ctx, pos) = resolve-origine(ctx, p, sx, sy)
      ctx = new-ctx
      let (x, y, ..) = pos
      canvas-pts.push((x, y))
    }
    
    if mark == none {
      line(..canvas-pts, stroke: stroke)
    } else {
      line(..canvas-pts, stroke: stroke, mark: mark)
    }
  })
}


// Détection d'une coordonnée nue (x, y) : un tableau de deux nombres.
#let _is-bare-coord(v) = (
  type(v) == array
    and v.len() == 2
    and (type(v.at(0)) == int or type(v.at(0)) == float)
    and (type(v.at(1)) == int or type(v.at(1)) == float)
)

// Normalise le dictionnaire `marker:` — accepté sous deux vocabulaires :
//   - interne : (marker-symbol, marker-size, marker-fill, marker-stroke, marker-angle)
//   - cetz (comme plot.add) : (mark, mark-fill, mark-stroke, mark-size)
// Renvoie un dictionnaire complet (défauts fusionnés) au vocabulaire interne,
// ou `none` si `marker` vaut `none`.
#let _normalize-marker(marker) = {
  if marker == none { return none }
  if marker.at("mark", default: none) != none {
    // style cetz : conversion vers le vocabulaire interne
    (
      marker-symbol: marker.at("mark", default: "o"),
      marker-size: marker.at("mark-size", default: 0.06),
      marker-fill: marker.at("mark-fill", default: red),
      marker-stroke: marker.at("mark-stroke", default: none),
      marker-angle: marker.at("marker-angle", default: 0deg),
    )
  } else {
    // style interne : fusion simple avec les défauts
    (marker-symbol: "o", marker-size: 0.06, marker-fill: red, marker-stroke: none, marker-angle: 0deg) + marker
  }
}


/// Marqueur et/ou étiquette optionnels à une ancre du plot OU à des
/// coordonnées (x, y) en unités du repère (O ; i, j) — voir resolve-origine.
/// Récupère automatiquement sx, sy (calculés par newFig). À appeler EN DEHORS
/// de plot.plot(...). Chaque objet est indépendant : si `marker` ou `label`
/// vaut `none`, on ne le dessine pas (les deux à `none` → rien du tout).
///
/// - origine (str, array): ancre "plot.<nom>", ou (x, y) en unités de données
/// - marker (dictionary, none): dictionnaire de marqueur — deux vocabulaires acceptés (interne `marker-*` ou cetz `mark:*`), voir draw-mark-shape ; none = pas de point
/// - label (dictionary, none): (label-text, label-distance, label-anchor, label-position, label-rotate, label-styles) ; none = pas d'étiquette
///
/// ```example
/// #newFig(
///   extra: (sx, sy) => {
///     import draw: *
///     // marqueur + étiquette (chacun est optionnel)
///     anchored-point((1, 1), marker: (marker-fill: red), label: (label-text: "A", label-position: 90deg))
///     // étiquette seule, sans point, tournée de 20°
///     anchored-point((-1, 1), marker: (marker-symbol: "x", marker-size: 0.06, marker-stroke: 1pt+purple), label: (label-text: text(fill: purple)[B], label-position: -135deg, label-rotate: 20deg))
///   },
///   { plot.add(domain: (-2, 2), x => calc.pow(x, 2), style: (stroke: blue + 0.5pt), samples: 50) },
/// )
/// ```
///
/// -> content
#let anchored-point(
  /// Ancre "plot.<nom>", ou (x, y) en unités de données.
  /// -> string | array
  origine,

  /// Dictionnaire de marqueur — deux vocabulaires acceptés, voir draw-mark-shape ;
  /// `none` = pas de point :
  ///   - interne : (marker-symbol, marker-size, marker-fill, marker-stroke, marker-angle)
  ///   - style cetz/plot.add : (mark, mark-fill, mark-stroke, mark-size)
  /// -> dictionary | none
  marker: (marker-symbol: "o", marker-size: 0.06, marker-fill: red, marker-stroke: none, marker-angle: 0deg),

  /// (label-text, label-distance, label-anchor, label-position, label-rotate, label-styles) ; none = pas d'étiquette.
  /// -> dictionary | none
  label: (
    label-text: "",
    label-distance: 8pt,
    label-anchor: "center",
    label-position: 0deg,
    label-rotate: 0deg,
    label-styles: (:),
  ),
) = {
  import draw: content, get-ctx

  // Rien à dessiner : on ne fait rien du tout
  if marker == none and label == none {
    return ()
  }

  // Normalise le dictionnaire marker (deux vocabulaires acceptés) puis
  // fusionne les défauts ; `none` = pas de point.
  let m = _normalize-marker(marker)
  let l = if label == none {
    none
  } else {
    (
      (
        label-text: "",
        label-distance: 8pt,
        label-anchor: "center",
        label-position: 0deg,
        label-rotate: 0deg,
        label-styles: (:),
      )
        + label
    )
  }

  get-ctx(ctx => {
    let (sx, sy) = ctx.at("helper-scale", default: (1, 1))
    let (ctx, pos) = resolve-origine(ctx, origine, sx, sy)
    let (x, y, ..) = pos

    // Marqueur (point), dessiné à (x, y) si demandé
    if m != none {
      draw-mark-shape(
        x,
        y,
        symbol: m.marker-symbol,
        size: m.marker-size,
        fill: m.marker-fill,
        stroke: m.marker-stroke,
        angle: m.marker-angle,
      )
    }

    // Étiquette, placée à `label-distance` du point dans la direction
    // `label-position` (0deg = droite, 90deg = haut...), avec `label-anchor`
    // comme ancre du texte à cette position, et tournée de `label-rotate`
    // autour de son propre centre
    if l != none {
      // label-styles est injecté dans text(...) : un contenu avec ses propres
      // styles (ex. text(fill: purple)[B]) garde la priorité ; label-styles ne
      // comble que ce qui n'est pas déjà précisé.
      let body = text(..l.label-styles, l.label-text)
      // distance en unités canvas (1 unité = 1 cm) : une longueur (pt, cm...)
      // est convertie ; un nombre brut est pris tel quel (déjà en cm)
      let dist = if type(l.label-distance) == length {
        l.label-distance / 1cm
      } else {
        l.label-distance
      }
      content(
        (x + dist * calc.cos(l.label-position), y + dist * calc.sin(l.label-position)),
        anchor: l.label-anchor,
        angle: l.label-rotate,
        body,
      )
    }
  })
}


/// Dessine plusieurs points (et, optionnellement, leurs étiquettes) en un
/// seul appel. Chaque élément peut être :
///   - une coordonnée nue (x, y) ou une ancre nue "plot.<nom>" : pas
///     d'étiquette ;
///   - un couple (origine, label-text) : même vocabulaire `origine` que
///     anchored-point, et label-text est soit le texte/contenu de
///     l'étiquette DE CE point, soit `none` pour sauter l'étiquette de ce
///     point.
/// Les deux formes peuvent être mélangées librement : chaque élément est
/// détecté automatiquement (un élément dont le premier élément est lui-même
/// un tableau/une chaîne est traité comme (origine, label-text)). Les
/// options `marker:`/`label:` sont partagées par tous les points (même
/// vocabulaire que anchored-point) — `label: none` (ou `marker: none`)
/// désactive les étiquettes (ou les marqueurs) pour TOUS les points d'un
/// coup, quel que soit ce que dit chaque élément. Les options `label:`
/// partagées acceptent aussi `label-styles`, un dictionnaire déversé dans
/// `text(...)` pour styler toutes les étiquettes d'un coup (un `label-text`
/// explicitement stylé reste prioritaire).
///
/// - points (array): par point, une coordonnée nue (x, y) / une ancre, ou un couple (origine, label-text) — label-text peut valoir none
/// - marker (dictionary, none): options de marqueur partagées (vocabulaire marker-* ou cetz mark:*), voir anchored-point ; none = aucun marqueur du tout
/// - label (dictionary, none): options d'étiquette partagées (label-text ici est surchargé par point, label-styles est déversé dans text()), voir anchored-point ; none = aucune étiquette du tout
///
/// ```example
/// #newFig(y-min: -1, y-max: 5,
///   extra: (sx, sy) => {
///     import draw: *
///     anchored-points(
///       (1, 1),             // point seul, sans label
///       ((2, 4), "B"),      // point avec label
///       ((3, 2), none),     // point seul, label explicitement désactivé
///       marker: (mark: "o", mark-fill: red, mark-stroke: 1pt + blue),
///       label: (label-position: -45deg, label-distance: 6pt, label-styles: (fill: blue, size: 0.8em)),
///     )
///   },
///   { plot.add(domain: (-3, 3), x => calc.pow(x, 2), style: (stroke: blue + 0.5pt), samples: 50) },
/// )
/// ```
///
/// -> content
#let anchored-points(
  /// Par point : une coordonnée nue (x, y) / une ancre, ou un couple (origine, label-text) — label-text peut valoir none.
  /// -> array
  ..points,

  /// Options de marqueur partagées (vocabulaire marker-* ou cetz mark:*), voir anchored-point ; none = aucun marqueur du tout.
  /// -> dictionary | none
  marker: (marker-symbol: "o", marker-size: 0.06, marker-fill: red, marker-stroke: none, marker-angle: 0deg),

  /// Options d'étiquette partagées (label-text ici est surchargé par point, label-styles est déversé dans text()), voir anchored-point ; none = aucune étiquette du tout.
  /// -> dictionary | none
  label: (
    label-text: "",
    label-distance: 8pt,
    label-anchor: "center",
    label-position: 0deg,
    label-rotate: 0deg,
    label-styles: (:),
  ),
) = {
  for item in points.pos() {
    // Détection du type de chaque élément :
    //  - coordonnée nue (x, y) ou ancre nue "plot.<nom>" → pas de label ;
    //  - sinon paire (origine, label-text), label-text pouvant être none.
    let (origine, txt) = if _is-bare-coord(item) or type(item) == str {
      (item, none)
    } else {
      (item.at(0), item.at(1))
    }
    let this-label = if label == none or txt == none {
      none
    } else {
      label + (label-text: txt)
    }
    anchored-point(origine, marker: marker, label: this-label)
  }
}

/// Flèche de dérivée à taille FIXE (cm), avec la pente corrigée pour
/// rester géométriquement cohérente dans un repère anisotrope. À appeler
/// EN DEHORS de plot.plot(...). Récupère automatiquement sx, sy (calculés
/// par newFig) : rien à refournir.
///
/// - origine (str, array): ancre "plot.<nom>", ou (x, y) en unités de données
/// - slope (float, int): pente RÉELLE en unités de données (ex. spline-dy(...))
/// - fill (color): couleur de la flèche
/// - length (float, int): longueur FIXE de la flèche, en cm
/// - stroke (stroke): épaisseur/couleur du trait
/// - mark-scale (float, int): taille de la pointe de flèche
///
/// ```example
/// #newFig(
///   extra: (sx, sy) => {
///     import draw: *
///     // tangente au point (1, f(1)) de pente 2
///     anchored-derivative-arrow((1, 1), 2, fill: red, stroke: red + 1.2pt)
///   },
///   { plot.add(domain: (-2, 2), x => calc.pow(x, 2), style: (stroke: blue + 0.5pt), samples: 50) },
/// )
/// ```
///
/// -> content
#let anchored-derivative-arrow(
  /// Ancre "plot.<nom>", ou (x, y) en unités de données.
  /// -> string | array
  origine,

  /// Pente RÉELLE en unités de données (ex. spline-dy(...)).
  /// -> float | int
  slope,

  /// Couleur de la flèche.
  /// -> color
  fill: black,

  /// Longueur FIXE de la flèche, en cm.
  /// -> float | int
  length: 1,

  /// Épaisseur/couleur du trait.
  /// -> stroke
  stroke: 1pt,

  /// Taille de la pointe de flèche.
  /// -> float | int
  mark-scale: .6,
) = {
  import draw: get-ctx, line
  let mark = (start: "stealth", end: "stealth", scale: mark-scale, fill: fill)
  get-ctx(ctx => {
    let (sx, sy) = ctx.at("helper-scale", default: (1, 1))
    let (ctx, pos) = resolve-origine(ctx, origine, sx, sy)
    let (x, y, ..) = pos // abscisse/ordonnée de l'origine, en unités canvas

    // pente "ajustée" à l'échelle réelle du dessin
    let screen-slope = slope * (sy / sx)
    let norm = calc.sqrt(1 + screen-slope * screen-slope)
    let dx = (length / 2) / norm
    let dy = dx * screen-slope

    line((x - dx, y - dy), (x + dx, y + dy), stroke: stroke, mark: mark)
  })
}

/// Trace les deux vecteurs de base (O ; vec(i), vec(j)), avec une longueur
/// de `length` unités de DONNÉES (défaut 1 = vecteur unitaire). Hampe et
/// pointe sont dessinées directement dans le repère du canvas : pas de
/// déformation liée à l'anisotropie du repère. Les deux segments forment
/// UNE seule polyligne continue (i) -- (O) -- (j) : aucun « décroché » à
/// l'origine. À appeler EN DEHORS de plot.plot(...). Récupère
/// automatiquement sx, sy (calculés par newFig) : rien à refournir.
///
/// - origine (str, array): ancre "plot.<nom>" ("plot.O" par défaut), ou (x, y) en unités de données
/// - x-length (float, int): longueur de vec(i), en unités de données
/// - y-length (float, int): longueur de vec(j), en unités de données
/// - fill (color): couleur des flèches et des labels
/// - stroke (auto, stroke): trait (auto = fill + 1pt)
/// - mark-scale (float, int): taille des pointes de flèche
/// -> content
#let anchored-basis-vectors(
  /// Ancre "plot.<nom>" ("plot.O" par défaut), ou (x, y) en unités de données.
  /// -> string | array
  origine: "plot.O",

  /// Longueur de vec(i), en unités de données.
  /// -> float | int
  x-length: 1,

  /// Longueur de vec(j), en unités de données.
  /// -> float | int
  y-length: 1,

  /// Couleur des flèches et des labels.
  /// -> color
  fill: red,

  /// Trait (auto = fill + 1pt).
  /// -> auto | stroke
  stroke: auto,

  /// Taille des pointes de flèche.
  /// -> float | int
  mark-scale: .5,
) = {
  import draw: content, get-ctx, line

  let stroke = if stroke == auto { fill + 1pt } else { stroke }
  let mark = (start: "stealth", end: "stealth", scale: mark-scale, fill: fill)

  get-ctx(ctx => {
    let (sx, sy) = ctx.at("helper-scale", default: (1, 1))
    let (ctx, pos) = resolve-origine(ctx, origine, sx, sy)
    let (x, y, ..) = pos

    // 1 unité de donnée = sx cm en x, sy cm en y.
    // Une seule polyligne continue (i) -- (O) -- (j), pas de décroché en O.
    line(
      (x + x-length * sx, y),
      (x, y),
      (x, y + y-length * sy),
      stroke: stroke,
      mark: mark,
    )

    // vec(i) au sud de la pointe de i ; vec(j) à l'ouest de la pointe de j
    content(
      (x + x-length * sx, y),
      anchor: "north",
      padding: 0.15,
      text(fill: fill, size: 0.7em)[$arrow(i)$],
    )
    content(
      (x, y + y-length * sy),
      anchor: "east",
      padding: 0.15,
      text(fill: fill, size: 0.7em)[$arrow(j)$],
    )
  })
}

/// Styles supplémentaires (flèches des axes), à fusionner avec ceux de
/// setAxes() via `set-style(axes: axes + extraStyles)`.
///
/// - x (dictionary): style de la pointe de flèche de l'axe des abscisses
/// - y (dictionary): style de la pointe de flèche de l'axe des ordonnées
/// -> dictionary
#let setExtraStyles(
  /// Style de la pointe de flèche de l'axe des abscisses.
  /// -> dictionary
  x: (mark: (end: "stealth", fill: black)),

  /// Style de la pointe de flèche de l'axe des ordonnées.
  /// -> dictionary
  y: (mark: (end: "stealth", fill: black)),
) = (
  x: x,
  y: y,
)

/// Dictionnaire de style des axes, à passer à `set-style(axes: ...)` (via
/// `newFig(axes: ...)`).
///
/// - grid (stroke): style de la grille principale
/// - minor-grid (stroke): style de la sous-grille
/// - shared-zero (content): étiquette affichée à l'origine commune des deux axes
/// - padding (length): dépassement au-delà des axes
/// - overshoot (length): dépassement des flèches des axes
/// - tick-stroke (stroke): couleur/épaisseur des ticks majeurs
/// - tick-length (float, int): longueur des ticks majeurs
/// - tick-minor-stroke (stroke): couleur/épaisseur des ticks mineurs
/// - tick-minor-length (float, int): longueur des ticks mineurs
/// -> dictionary
#let setAxes(
  /// Style de la grille principale.
  /// -> stroke
  grid: (stroke: gray + 0.4pt),

  /// Style de la sous-grille.
  /// -> stroke
  minor-grid: (stroke: gray.lighten(60%) + 0.2pt),

  /// Étiquette affichée à l'origine commune des deux axes.
  /// -> content
  shared-zero: text(size: 8pt, fill: red)[$O$],

  /// Dépassement au-delà des axes.
  /// -> length
  padding: 0pt,

  /// Dépassement des flèches des axes.
  /// -> length
  overshoot: 8pt,

  /// Couleur/épaisseur des ticks majeurs.
  /// -> stroke
  tick-stroke: black + 0.5pt,
  
  /// Longueur des ticks majeurs.
  /// -> float | int
  tick-length: 0.1,

  /// Couleur/épaisseur des ticks mineurs.
  /// -> stroke
  tick-minor-stroke: gray + 0.3pt,

  /// Longueur des ticks mineurs.
  /// -> float | int
  tick-minor-length: 0,
) = (
  grid: grid,
  minor-grid: minor-grid,
  shared-zero: shared-zero,
  padding: padding,
  overshoot: overshoot,
  tick: (stroke: tick-stroke, length: tick-length, minor-stroke: tick-minor-stroke, minor-length: tick-minor-length),
)

/// Alias pour compatibilité avec l'ancien nom.
/// -> function
#let mesaxes = setAxes

/// Options par défaut de `plot.plot(...)`, sous forme de dictionnaire.
/// Peut être appelée telle quelle (valeurs "génériques"), mais `newFig`
/// l'appelle en lui injectant SES PROPRES size/x-min/x-max/y-min/y-max
/// (et x-format/y-format en fonction de `repere:`), de sorte que tu n'as
/// jamais à répéter ces valeurs à deux endroits. Tout paramètre
/// supplémentaire non prévu explicitement (ex. y-equal:) passe tel quel
/// via `..more` et sera transmis à plot.plot.
///
/// - size (array): taille physique du plot (largeur, hauteur), en cm
/// - x-min (float, int): borne inférieure du domaine en x
/// - x-max (float, int): borne supérieure du domaine en x
/// - y-min (float, int): borne inférieure du domaine en y
/// - y-max (float, int): borne supérieure du domaine en y
/// - name (str): nom du plot (pour "plot.<nom>" dans plot.add-anchor)
/// - x-tick-step (float, int): pas entre deux graduations majeures en x
/// - x-minor-tick-step (float, int): pas entre deux graduations mineures en x
/// - y-tick-step (float, int): pas entre deux graduations majeures en y
/// - y-minor-tick-step (float, int): pas entre deux graduations mineures en y
/// - axis-style (str): style des axes ("school-book", etc.)
/// - x-format (function): mise en forme des valeurs affichées sur l'axe des x
/// - y-format (function): mise en forme des valeurs affichées sur l'axe des y
/// - x-label (content): étiquette de l'axe des x
/// - y-label (content): étiquette de l'axe des y
/// - x-grid (str, none): grille verticale ("major", "minor", "both" ou none)
/// - y-grid (str, none): grille horizontale ("major", "minor", "both" ou none)
/// -> dictionary
#let setPlot(
  /// Taille physique du plot (largeur, hauteur), en cm.
  /// -> array
  size: (12, 6.5),

  /// Borne inférieure du domaine en x.
  /// -> float | int
  x-min: -3,

  /// Borne supérieure du domaine en x.
  /// -> float | int
  x-max: 3,

  /// Borne inférieure du domaine en y.
  /// -> float | int
  y-min: -3.5,

  /// Borne supérieure du domaine en y.
  /// -> float | int
  y-max: 3,

  /// Nom du plot (pour "plot.<nom>" dans plot.add-anchor).
  /// -> string
  name: "plot",

  /// Pas entre deux graduations majeures en x.
  /// -> float | int
  x-tick-step: 1,

  /// Pas entre deux graduations mineures en x.
  /// -> float | int
  x-minor-tick-step: 0.1,

  /// Pas entre deux graduations majeures en y.
  /// -> float | int
  y-tick-step: 1,

  /// Pas entre deux graduations mineures en y.
  /// -> float | int
  y-minor-tick-step: 0.1,

  /// Style des axes ("school-book", etc.).
  /// -> string
  axis-style: "school-book",

  /// Mise en forme des valeurs affichées sur l'axe des x.
  /// -> function
  x-format: v => if v != 1 { text(size: 8pt)[#v] },

  /// Mise en forme des valeurs affichées sur l'axe des y.
  /// -> function
  y-format: v => if v != 1 { text(size: 8pt)[#v] },

  /// Étiquette de l'axe des x.
  /// -> content
  x-label: text(size: 0.8em)[$x$],

  /// Étiquette de l'axe des y.
  /// -> content
  y-label: text(size: 0.8em)[$y$],
  
  /// Grille verticale ("major", "minor", "both" ou none).
  /// -> string | none
  x-grid: "both",

  /// Grille horizontale ("major", "minor", "both" ou none).
  /// -> string | none
  y-grid: "both",

  /// Paramètres supplémentaires transmis tels quels à plot.plot.
  /// -> any
  ..more,
) = (
  size: size,
  name: name,
  x-min: x-min,
  x-max: x-max,
  y-min: y-min,
  y-max: y-max,
  x-tick-step: x-tick-step,
  x-minor-tick-step: x-minor-tick-step,
  y-tick-step: y-tick-step,
  y-minor-tick-step: y-minor-tick-step,
  axis-style: axis-style,
  x-format: x-format,
  y-format: y-format,
  x-label: x-label,
  y-label: y-label,
  x-grid: x-grid,
  y-grid: y-grid,
  ..more.named(),
)

/// Encapsule `plot.plot(...)` : reçoit un dictionnaire d'options déjà prêt
/// (typiquement produit par `setPlot(...)`) et le `body` qui va DANS le
/// plot (tes `plot.add(...)`, `plot.add-anchor(...)`, `plot.annotate(...)`).
/// Ajoute automatiquement `plot.add-anchor("O", (0, 0))` : tu n'as plus
/// besoin de le faire toi-même, l'ancre "plot.O" est toujours disponible
/// pour `anchored-basis-vectors(...)` etc.
///
/// - options (dictionary): options de plot.plot, typiquement produites par setPlot(...)
/// - body (content): contenu placé dans plot.plot (plot.add, plot.add-anchor, plot.annotate...)
/// -> content
#let monplot(
  /// Options de plot.plot, typiquement produites par setPlot(...).
  /// -> dictionary
  options,

  /// Contenu placé dans plot.plot (plot.add, plot.add-anchor, plot.annotate...).
  /// -> content
  body,
) = {
  plot.plot(
    ..options,
    {
      plot.add-anchor("O", (0, 0))
      body
    },
  )
}

/// Fonction "tout-en-un" pour construire une figure : calcule sx, sy
/// automatiquement (plus besoin d'appeler plot-scale toi-même), ouvre le
/// canvas et applique le style des axes, appelle monplot(...) avec les
/// options fusionnées de setPlot(...), et ajoute, si fourni, le contenu
/// HORS du plot mais DANS le canvas (accès à sx, sy). Si repere: true
/// (défaut), ajoute automatiquement le repère (O ; i, j) ET masque la
/// graduation "1" sur les axes (puisqu'elle fait double emploi avec les
/// flèches i, j) ; si repere: false, pas de flèches, et la graduation "1"
/// redevient visible comme les autres. Un x-format/y-format donné dans
/// `plot:` prend le pas sur celui piloté par `repere:` — mais ne mets pas
/// les deux à la fois pour la même clé (x-format ou y-format), Typst
/// refuse un argument nommé en double.
/// - size (array): dimensions physiques du plot (largeur, hauteur), en cm
/// - x-min (float | int): borne inférieure du domaine en x
/// - x-max (float | int): borne supérieure du domaine en x
/// - y-min (float | int): borne inférieure du domaine en y
/// - y-max (float | int): borne supérieure du domaine en y
/// - axes (dictionary): style des axes, voir setAxes()
/// - extraStyles (dictionary): styles des flèches de base (i, j), voir setExtraStyles()
/// - repere (bool): affiche/masque (O ; vec(i), vec(j)) et la graduation "1" (voir description)
/// - plot (dictionary): surcharge des options de setPlot() (ex. (x-tick-step: 0.5))
/// - extra (function, none): (sx, sy) => content, dessiné après le plot, dans le canvas
/// - body (content): contenu placé DANS plot.plot (plot.add, plot.add-anchor, plot.annotate...)
/// ```
/// #newFig(
///   // contenu DANS plot.plot
///   {
///     plot.add(domain: (-3, 3), x => x * 0, style: (stroke: gray + 0.5pt), samples: 2)
///     plot.add-anchor("p0", (-2, -1))
///   },
///   // contenu HORS plot, dans le canvas (accès à sx, sy)
///   extra: (sx, sy) => {
///     import draw: *
///     anchored-point("plot.p0", marker: (marker-fill: red), label: (label-text: "A", label-position: 90deg))
///     anchored-basis-vectors(fill: red)
///   },
/// )
/// ```
/// -> content
#let newFig(
  /// Dimensions physiques du plot (largeur, hauteur), en cm.
  /// -> array
  size: (12.0, 6.5),
  
  /// Borne inférieure du domaine en x.
  /// -> float|int
  x-min: -3.0,
  
  /// Borne supérieure du domaine en x.
  /// -> float|int
  x-max: 3.0,
  
  /// Borne inférieure du domaine en y.
  /// -> float|int
  y-min: -3.5,
  
  /// Borne supérieure du domaine en y.
  /// -> float|int
  y-max: 3.0,
  
  /// Style des axes, voir setAxes().
  /// -> dictionary
  axes: setAxes(),
  
  /// Styles des flèches de base (i, j), voir setExtraStyles().
  /// -> dictionary
  extraStyles: setExtraStyles(),
  
  /// Affiche/masque (O ; vec(i), vec(j)) et la graduation "1" ; si false, l'origine est étiquetée "0" (sans le rouge de O).
  /// -> bool
  repere: true,
  
  /// Surcharge des options de setPlot() (ex. (x-tick-step: 0.5)).
  /// -> dictionary
  plot: (:),
  
  /// (sx, sy) => content, dessiné après le plot, dans le canvas.
  /// -> function | none
  extra: none,
  
  /// Contenu placé DANS plot.plot (plot.add, plot.add-anchor, plot.annotate...).
  /// -> content
  body,
) = {
  let (sx, sy) = plot-scale(size, (x-min, x-max), (y-min, y-max))
  
  // Avec repere: true, la valeur "1" est masquée (les flèches i, j la
  // montrent déjà) ; avec repere: false, tout s'affiche, "1" compris.
  let tick-format = if repere {
    v => if v != 1 { text(size: 8pt)[#v] }
  } else {
    v => text(size: 8pt)[#v]
  }

  // Avec repere: false, l'origine est étiquetée "0" (et sans le rouge de O).
  let axes = if repere {
    axes
  } else {
    axes + (shared-zero: text(size: 8pt)[$0$])
  }
  
  let plot-options = setPlot(
    size: size,
    x-min: x-min,
    x-max: x-max,
    y-min: y-min,
    y-max: y-max,
    x-format: tick-format,
    y-format: tick-format,
    ..plot,
  )
  
  canvas({
    import draw: *
    
    // Rend sx, sy récupérables via get-ctx (utilisé par anchored-basis-vectors,
    // anchored-point...) sans avoir à les repasser en argument.
    set-ctx(ctx => ctx + (helper-scale: (sx, sy)))
    
    set-style(axes: axes + extraStyles)
    
    monplot(plot-options, body)
    
    if extra != none {
      extra(sx, sy)
    }
    
    if repere {
      anchored-basis-vectors(fill: red)
    }
  })
}
