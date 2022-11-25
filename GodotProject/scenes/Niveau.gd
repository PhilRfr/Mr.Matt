extends Node2D

var tilemap : TileMap
var pommes : Label

var historique = []
var chaine_jeu = ""

enum EtatJeu{
	JOUEUR, CALCUL, PERDU, GAGNE
}

const TILES = ["apple", "boulder", "empty", "grass", "player", "wall"]
const ASCII = ['+', '*', ' ', '-', 'H', '#']

const GLISSANT = ["boulder"]
const VIDE = ["empty"]
const TOMBER = ["empty", "player"]
const MARCHABLE = ["empty", "apple", "grass"]

var etat_actuel = EtatJeu.JOUEUR

var position_joueur : Vector2 = Vector2.ZERO
var pommes_restantes : int = 0
var deplacements : int = 0

var dernier_delai = 0
const DELAI = 0.01

func _physics_process(delta):
	dernier_delai += delta
	while (dernier_delai - DELAI > 0):
		dernier_delai -= DELAI
		if etat_actuel == EtatJeu.CALCUL:
			phase_calcul()

func phase_calcul():
	calculer_etat_suivant()
	if pommes_restantes == 0 and etat_actuel == EtatJeu.JOUEUR:
		declencher_gagne()

func charger_niveau(niveau : String):
	var parties = niveau.split("/")
	var contenu_niveau = Globals.jeux[parties[0]]["contents"][parties[1]]
	charger_chaine(contenu_niveau)

func charger_chaine(chaine: String):
	var lignes = chaine.split('\n')
	var x = 0
	var y = 0
	tilemap.clear()
	for l in lignes:
		x = 0
		for c in l:
			var target = Vector2(x, y)
			var pos = ASCII.find(c)
			if pos >= 0:
				var tile = tilemap.tile_set.find_tile_by_name(TILES[pos])
				tilemap.set_cellv(target, tile)
			if c == 'H':
				position_joueur = target
			if c == '+':
				pommes_restantes += 1
			x += 1
		y += 1
		maj_hud()

func maj_hud():
	$HUD.text = "Pommes restantes : "+str(pommes_restantes) + " C : "+ Globals.compress(chaine_jeu)

func _input(event):
	if Input.is_action_pressed("annuler"):
		annuler()
		return
	if etat_actuel != EtatJeu.JOUEUR:
		return
	if Input.is_action_pressed("mouvement_bas"):
		deplacement(Vector2.DOWN, "B")
	elif Input.is_action_pressed("mouvement_haut"):
		deplacement(Vector2.UP, "H")
	elif Input.is_action_pressed("mouvement_gauche"):
		deplacement(Vector2.LEFT, "G")
	elif Input.is_action_pressed("mouvement_droite"):
		deplacement(Vector2.RIGHT, "D")

func deplacement_possible(d : Vector2) -> bool:
	var cible = position_joueur + d
	if d.x == 0 and d.y == 0:
		return false
	var tuile = tilemap.get_cellv(cible)
	if tuile < 0:
		return false
	var nom_tuile = nom_tuile(cible)
	if nom_tuile in MARCHABLE:
		return true
	if nom_tuile == "boulder" and d.y == 0:
		var cible_derriere = cible + d
		if nom_tuile(cible_derriere) == "empty":
			return true
	return false

func nom_tuile(cellule : Vector2):
	var cell = tilemap.get_cellv(cellule)
	if cell >= 0:
		return tilemap.tile_set.tile_get_name(cell)
	return null

func echanger(source : Vector2, cible : Vector2):
	var t = tilemap.get_cellv(source)
	tilemap.set_cellv(source, tilemap.get_cellv(cible))
	tilemap.set_cellv(cible, t)

func mettre_tuile(cible : Vector2, nom : String):
	tilemap.set_cellv(cible, tilemap.tile_set.find_tile_by_name(nom))

func deplacer(d : Vector2):
	deplacements += 1
	var cible = position_joueur + d
	var nom = nom_tuile(cible)
	if nom in MARCHABLE:
		tilemap.set_cellv(cible, tilemap.tile_set.find_tile_by_name("empty"))
		echanger(position_joueur, cible)
	elif nom == "boulder":
		var derriere = cible + d
		echanger(cible, derriere)
		echanger(cible, position_joueur)
	if nom == "apple":
		$"/root/SoundManager".play("pick")
	position_joueur = cible

func etat_suivant():
	etat_actuel = EtatJeu.CALCUL

func calculer_etat_suivant():
	if etat_actuel != EtatJeu.CALCUL:
		return
	var cellules = tilemap.get_used_cells()
	etat_actuel = EtatJeu.JOUEUR
	cellules.sort()
	var i = len(cellules) - 1
	pommes_restantes = 0
	while i >= 0:
		if etat_actuel in [EtatJeu.GAGNE, EtatJeu.PERDU]:
			return
		var coords = cellules[i]
		var nom = nom_tuile(coords)
		if "boulder" in nom:
			if calculer_rocher(coords, nom):
				break
		elif "apple" in nom:
			pommes_restantes += 1
		i -= 1
	maj_hud()

func calculer_rocher(coords : Vector2, nom : String) -> bool:
	var en_bas = coords + Vector2.DOWN
	var tuile_en_bas = nom_tuile(en_bas)
	var retour = false
	if nom == "boulder":
		if tuile_en_bas == "empty":
			mettre_tuile(coords, "falling_boulder")
			etat_actuel = EtatJeu.CALCUL
			retour = true
	elif nom == "falling_boulder":
		if tuile_en_bas == "player":
			mettre_tuile(coords, "boulder")
			mettre_tuile(position_joueur, "lost")
			declencher_perdu()
		elif tuile_en_bas in VIDE:
			echanger(en_bas, coords)
			etat_actuel = EtatJeu.CALCUL
			retour = true
		elif tuile_en_bas in GLISSANT:
			var tuile_gauche = nom_tuile(coords + Vector2.LEFT)
			var tuile_droite = nom_tuile(coords + Vector2.RIGHT)
			var tuile_bas_gauche = nom_tuile(coords + Vector2.LEFT + Vector2.DOWN)
			var tuile_bas_droite = nom_tuile(coords + Vector2.RIGHT + Vector2.DOWN)
			if tuile_gauche in VIDE and tuile_bas_gauche in TOMBER:
				$"/root/SoundManager".play("boulder")
				echanger(coords, coords + Vector2.LEFT)# + Vector2.DOWN)
				etat_actuel = EtatJeu.CALCUL
				retour = true
			elif tuile_droite in VIDE and tuile_bas_droite in TOMBER:
				$"/root/SoundManager".play("boulder")
				echanger(coords, coords + Vector2.RIGHT)# + Vector2.DOWN)
				etat_actuel = EtatJeu.CALCUL
				retour = true
			else:
				$"/root/SoundManager".play("boulder")
				mettre_tuile(coords, "boulder")
		else:
			$"/root/SoundManager".play("boulder")
			mettre_tuile(coords, "boulder")
	return false

func deplacement(d : Vector2, c : String):
	if etat_actuel != EtatJeu.JOUEUR:
		return
	if deplacement_possible(d):
		empiler_etat()
		chaine_jeu += c
		deplacer(d)
		etat_suivant()
	else:
		$"/root/SoundManager".play("error")

func _ready():
	tilemap = $TileMap
	charger_niveau(Globals.jeu_a_charger)

func declencher_gagne():
	etat_actuel = EtatJeu.GAGNE
	$"/root/SoundManager".play("win")
	$HUD.text = "Bravo !"

func declencher_perdu():
	etat_actuel = EtatJeu.PERDU
	$"/root/SoundManager".play("loss")
	$HUD.text = "Qu'as-tu fait à Mr. Matt ?"

func annuler():
	if len(historique) == 0:
		return
	elif len(historique) == 1:
		charger(historique[0])
	else:
		charger(historique.pop_back())

func empiler_etat():
	var etat = {}
	etat["cellules"] = {}
	for i in tilemap.get_used_cells():
		etat["cellules"][i] = tilemap.get_cellv(i)
	etat["position_joueur"] = position_joueur
	etat["pommes"] = pommes_restantes
	etat["chaine_jeu"] = chaine_jeu
	historique.push_back(etat)

func charger(etat):
	for c in etat["cellules"]:
		tilemap.set_cellv(c, etat["cellules"][c])
	position_joueur = etat["position_joueur"]
	pommes_restantes = etat["pommes"]
	chaine_jeu = etat["chaine_jeu"]
	etat_actuel = EtatJeu.JOUEUR
	maj_hud()
