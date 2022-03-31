require daslib/media
require WorldManager
require Player
require Soldier
require Character
require ChargeTank
require Turret
require Heart

def createPlayer
    var player: Character? = new Player()
    player->Init()

    return player

def createSoldier
    var soldier: Character? = new Soldier()
    soldier->Init()

    return soldier

def createChargeTank
    var chargeTank: Character? = new ChargeTank()
    chargeTank->Init()

    return chargeTank

def createTurret
    var turret: Character? = new Turret()
    turret->Init()

    return turret

def createHeart
    var heart: Character? = new Heart()
    heart->Init()

    return heart

var mainTheme : SoundHandle

[export]
def initialize

    mainTheme  = create_managed_sound("Assets/SFX/Badlands.mp3")
    mainTheme |> play_sound(0.15f)

    set_font_name("Assets/GUI/kongtext.ttf")
    set_font_size(20)

    set_window_title("Happy birthday to me")
    set_resolution(800, 600)

    manager = new WorldManager()
    manager->Init(@@createPlayer, @@createSoldier, @@createChargeTank, @@createTurret, @@createHeart)

    manager->LoadZone("Assets/Zones/Zone_01.map")

    return

[export]
def act(dt: float)

    if get_key(VK_ESCAPE)
        schedule_quit_game()

    manager->Update(dt)

    return

[export]
def draw

    enable_alpha_blend()

    manager->Draw()

    return
