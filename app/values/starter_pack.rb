# frozen_string_literal: true

class StarterPack
  CLASS_MAX = 11

  KEYS = %w[neutral fantasy scifi].freeze

  CLASSES_RANGE   = (4..30)
  DEFAULT_CLASSES = 12

  LABELS = {
    'neutral' => 'Neutralny',
    'fantasy' => 'Fantasy',
    'scifi'   => 'Sci-fi',
  }.freeze

  DESCRIPTIONS = {
    'neutral' => 'Bez fabularnego klimatu. Pasuje do każdego przedmiotu.',
    'fantasy' => 'Zamki, zakony i rycerskie tytuły.',
    'scifi'   => 'Statki, załogi i kosmiczne misje.',
  }.freeze

  TEMPLATE_NAME = 'Zajęcia'

  Rank     = Data.define(:index, :name, :threshold, :discount, :icon_glyph)
  Badge    = Data.define(:index, :name, :didactic_description, :story_description, :discount,
                         :icon_glyph,)
  Item     = Data.define(:index, :name, :price, :didactic_description, :story_description, :icon_glyph,
                         :unlock_rank, :min_rank_for_discount, :discount_badges, :can_buy_at_0_lives,)
  Category = Data.define(:index, :didactic_description, :story_description, :reward)

  CATEGORIES = [
    ['Obecność',                   1],
    ['Punktualność',               1],
    ['Wejściówka zaliczona',       1],
    ['Wejściówka ≥ średnia grupy', 2],
    ['Zgłoszenie do zadania',      2],
    ['Zadanie zrobione poprawnie', 1],
    ['Pomoc innym',                2],
    ['Ciekawa uwaga',              1],
  ].freeze

  RANK_FRACTIONS = [0.0, 0.15, 0.30, 0.50, 0.75].freeze
  RANK_DISCOUNTS = [0, 3, 5, 10, 15].freeze

  BADGE_RULES = [
    'Pierwsza wejściówka bez błędów',
    'Obecność na wszystkich zajęciach w miesiącu',
    'Co najmniej 3 razy pomógł innym',
    'Co najmniej 3 ciekawe uwagi',
    '3 wejściówki z rzędu ≥ średniej grupy',
    'Wyjaśnienie trudnego zadania całej grupie',
  ].freeze

  BADGE_DISCOUNTS = [2, 5, 5, 3, 5, 7].freeze

  ITEMS = [
    {
      name:            '+5 minut do wejściówki',
      x:               1.0,
      glyph:           'clock',
      unlock:          nil,
      discount_rank:   2,
      discount_badges: [],
      didactic:        'Dodaje 5 minut do czasu na najbliższą wejściówkę.',
    },
    {
      name:            'Konsultacja',
      x:               1.5,
      glyph:           'chat',
      unlock:          nil,
      discount_rank:   2,
      discount_badges: [],
      didactic:        'Kwadrans konsultacji z prowadzącym poza zajęciami.',
    },
    {
      name:            'Poprawa wejściówki',
      x:               1.0,
      glyph:           'retake',
      unlock:          1,
      discount_rank:   3,
      discount_badges: [],
      didactic:        'Pozwala napisać jedną wejściówkę jeszcze raz.',
    },
    {
      name:            'Bezpieczna poprawa',
      x:               2.0,
      glyph:           'shield',
      unlock:          2,
      discount_rank:   3,
      discount_badges: [1, 3],
      didactic:        'Poprawa wejściówki bez ryzyka — liczy się lepszy z dwóch wyników.',
    },
    {
      name:            'Usprawiedliwienie',
      x:               2.5,
      glyph:           'note',
      unlock:          2,
      discount_rank:   3,
      discount_badges: [],
      didactic:        'Usprawiedliwia jedną nieobecność, bez utraty życia.',
    },
    {
      name:            '1up: odzyskanie życia',
      m:               0.25,
      glyph:           'heartPlus',
      unlock:          nil,
      discount_rank:   4,
      discount_badges: [3, 5, 2],
      at_zero_lives:   true,
      didactic:        'Przywraca jedno utracone życie.',
    },
    {
      name:            '+0.5 oceny końcowej',
      m:               0.60,
      glyph:           'percent',
      unlock:          3,
      discount_rank:   4,
      discount_badges: [5, 1],
      didactic:        'Podnosi ocenę końcową o pół stopnia.',
    },
  ].freeze

  RANK_NAMES = {
    'neutral' => %w[Nowicjusz Uczeń Adept Ekspert Mistrz],
    'fantasy' => %w[Giermek Rycerz Kasztelan Hetman Król],
    'scifi'   => %w[Kadet Pilot Nawigator Komandor Admirał],
  }.freeze

  RANK_GLYPHS = {
    'neutral' => %w[chev1 chev2 shield starPlus crown],
    'fantasy' => %w[chev1 chev2 shield crown carrotStar],
    'scifi'   => %w[chev1 chev2 rocket compass crown],
  }.freeze

  BADGE_NAMES = {
    'neutral' => ['Bez skazy',
                  'Stała obecność',
                  'Pomocna dłoń',
                  'Iskra ciekawości',
                  'Seria sukcesów',
                  'Głos grupy',],
    'fantasy' => ['Czysta klinga',
                  'Wierna straż',
                  'Tarcza drużyny',
                  'Księga mądrości',
                  'Pasmo zwycięstw',
                  'Bard drużyny',],
    'scifi'   => ['Czysty lot',
                  'Zawsze na pokładzie',
                  'Mechanik załogi',
                  'Sygnał z kosmosu',
                  'Seria misji',
                  'Głos floty',],
  }.freeze

  BADGE_GLYPHS = {
    'neutral' => %w[starPlus shield heartPlus bolt starTrail crew],
    'fantasy' => %w[starPlus shield heartPlus bolt starTrail crown],
    'scifi'   => %w[starPlus rocket wrench compass starTrail crew],
  }.freeze

  BADGE_STORIES = {
    'neutral' => [nil] * 6,
    'fantasy' => ['Stal bez jednej rysy — pierwszy pojedynek wygrany bez draśnięcia.',
                  'Stałeś na posterunku każdej nocy tego miesiąca.',
                  'Trzykrotnie zasłoniłeś towarzysza własną tarczą.',
                  'Trzy razy dopisałeś coś, czego w księgach jeszcze nie było.',
                  'Trzy potyczki z rzędu rozstrzygnięte na twoją korzyść.',
                  'Wytłumaczyłeś całej drużynie to, czego nikt inny nie potrafił nazwać.',],
    'scifi'   => ['Pierwszy lot bez jednego odczytu w czerwieni.',
                  'Ani jednej zmiany opuszczonej w tym cyklu.',
                  'Trzy razy postawiłeś na nogi cudzy sprzęt.',
                  'Trzy razy wychwyciłeś sygnał, który inni przegapili.',
                  'Trzy misje z rzędu zaliczone powyżej normy floty.',
                  'Twoje wyjaśnienie poszło na cały kanał i wszyscy zrozumieli.',],
  }.freeze

  ITEM_STORIES = {
    'neutral' => [nil] * 7,
    'fantasy' => ['Klepsydra sypie piaskiem wolniej, niż powinna.',
                  'Audiencja u mistrza zakonu.',
                  'Drugie podejście do pojedynku.',
                  'Pojedynek na tępe klingi — przegrana nic nie kosztuje.',
                  'List żelazny tłumaczący twoją nieobecność.',
                  'Eliksir przywracający życie.',
                  'Pieczęć króla na twoim świadectwie.',],
    'scifi'   => ['Chwilowe spowolnienie zegara pokładowego.',
                  'Połączenie z komandorem poza godzinami służby.',
                  'Drugie podejście do symulacji.',
                  'Lot treningowy — awaria nic nie kosztuje.',
                  'Wpis do dziennika usprawiedliwiający nieobecność.',
                  'Regeneracja w kapsule medycznej.',
                  'Awans wpisany do akt floty.',],
  }.freeze

  CATEGORY_STORIES = {
    'neutral' => [nil] * 8,
    'fantasy' => ['Stawiłeś się na zbiórce.',
                  'Na miejscu, zanim zabrzmiał róg.',
                  'Próba sprawności zaliczona.',
                  'Wynik powyżej średniej drużyny.',
                  'Zgłosiłeś się na ochotnika.',
                  'Zadanie wykonane bez zarzutu.',
                  'Podałeś rękę towarzyszowi.',
                  'Rzuciłeś światło na rzecz, której nikt nie dostrzegł.',],
    'scifi'   => ['Zameldowałeś się na pokładzie.',
                  'Na stanowisku przed odliczaniem.',
                  'Test kwalifikacyjny zaliczony.',
                  'Wynik powyżej średniej załogi.',
                  'Zgłosiłeś się do zadania.',
                  'Zadanie wykonane zgodnie z procedurą.',
                  'Wsparłeś innego członka załogi.',
                  'Zauważyłeś coś, co umknęło czujnikom.',],
  }.freeze

  class << self
    def include?(key) = KEYS.include?(key.to_s)

    def label_for(key) = LABELS.fetch(key.to_s, key.to_s)

    def description_for(key) = DESCRIPTIONS.fetch(key.to_s, '')

    def for(pack:, classes:)
      new(pack:    include?(pack) ? pack.to_s : KEYS.first,
          classes: classes.to_i.clamp(CLASSES_RANGE.min, CLASSES_RANGE.max),)
    end
  end

  def initialize(pack:, classes:)
    @pack    = pack
    @classes = classes
  end

  attr_reader :pack, :classes

  def label       = self.class.label_for(pack)
  def description = self.class.description_for(pack)

  def total_earnable = classes * CLASS_MAX

  def ranks
    @ranks ||= begin
      names  = RANK_NAMES[pack]
      glyphs = RANK_GLYPHS[pack]

      thresholds = RANK_FRACTIONS.each_with_object([]) do |fraction, kept|
        value = round_to_five(fraction * total_earnable)
        kept << (kept.empty? ? value : [value, kept.last + 1].max)
      end

      names.each_with_index.map do |name, index|
        Rank.new(index: index, name: name, threshold: thresholds[index],
                 discount: RANK_DISCOUNTS[index], icon_glyph: glyphs[index],)
      end
    end
  end

  def badges
    @badges ||= begin
      names   = BADGE_NAMES[pack]
      glyphs  = BADGE_GLYPHS[pack]
      stories = BADGE_STORIES[pack]

      names.each_with_index.map do |name, index|
        Badge.new(index: index, name: name,
                  didactic_description: BADGE_RULES[index],
                  story_description: stories[index],
                  discount: BADGE_DISCOUNTS[index], icon_glyph: glyphs[index],)
      end
    end
  end

  def items
    @items ||= begin
      stories = ITEM_STORIES[pack]

      ITEMS.each_with_index.map do |spec, index|
        Item.new(index: index, name: spec[:name], price: price_for(spec),
                 didactic_description: spec[:didactic],
                 story_description: stories[index],
                 icon_glyph: spec[:glyph],
                 unlock_rank: spec[:unlock],
                 min_rank_for_discount: spec[:discount_rank],
                 discount_badges: spec[:discount_badges],
                 can_buy_at_0_lives: spec.fetch(:at_zero_lives, false),)
      end
    end
  end

  def categories
    @categories ||= begin
      stories = CATEGORY_STORIES[pack]

      CATEGORIES.each_with_index.map do |(label, reward), index|
        Category.new(index: index, didactic_description: label,
                     story_description: stories[index], reward: reward,)
      end
    end
  end

  private

  def price_for(spec)
    raw = spec[:x] ? spec[:x] * CLASS_MAX : spec[:m] * total_earnable

    [raw.round, 1].max
  end

  def round_to_five(value) = (value / 5.0).round * 5
end
