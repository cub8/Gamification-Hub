# frozen_string_literal: true

DESCRIPTION = <<~DESC
  Galaktyka jest wielka, ale nasze uszy są większe!
  Dołącz do pionierów, którzy zamienili nory na stacje orbitalne.
  Walczymy o prestiż, przetrwanie i pełne brzuchy, zbierając Złote Marchewki w świecie, gdzie grawitacja to tylko sugestia.
  Pamiętaj: w kosmosie nikt nie usłyszy Twojego chrupania... chyba że zapomnisz wyłączyć interkom
DESC

user = User.find_by # find your user in production

story_group = StoryGroup.create!(
  owner:         user,
  name:          'Kosmiczne króliki',
  description:   DESCRIPTION,
  currency_name: 'Złota Marchewka',
  default_lives: 3,
)

RANKS = [
  { name: 'Rekrut', required_currency_value: 0, discount: 0 },
  { name: 'Kosmiczny Królik', required_currency_value: 40, discount: 3 },
  { name: 'Pilot Marcheton-7', required_currency_value: 80, discount: 5 },
  { name: 'Strateg Imperium', required_currency_value: 130, discount: 10 },
  { name: 'Mistrz Marchewki', required_currency_value: 190, discount: 20 },
].freeze

RANKS.each do |rank_data|
  Rank.create!(story_group: story_group, **rank_data)
end

BADGES = [
  {
    name:                 'Dzielny Królik',
    discount:             2,
    story_description:    'Królik nie uciekł z pola misji',
    didactic_description: 'Niezaliczona wejściówka, ale zdobyte co najmniej 4 marchewki ' \
                          'łącznie w innych kategoriach na danym laboratorium',
  },
  {
    name:                 'Zawsze na pokładzie',
    discount:             3,
    story_description:    'Rekrut nigdy nie opuścił statku',
    didactic_description: 'Co najmniej 26 marchewek za obecność',
  },
  {
    name:                 'Złota Marchewka',
    discount:             2,
    story_description:    'Idealna misja',
    didactic_description: 'Pierwszy raz wejściówka bez błędów',
  },
  {
    name:                 'Strateg Floty',
    discount:             3,
    story_description:    'Dowództwo zauważyło skuteczność',
    didactic_description: 'Co najmniej 3 wejściówki z rzędu ≥ średnia grupy',
  },
  {
    name:                 'Perfekcyjny Lot',
    discount:             5,
    story_description:    'Lot bez najmniejszej rysy',
    didactic_description: 'Co najmniej 3 wejściówki z rzędu bez błędów',
  },
  {
    name:                 'Mechanik Załogi',
    discount:             2,
    story_description:    'Królik naprawiał cudze statki',
    didactic_description: 'Zdobyte co najmniej 3 marchewki za pomoc innym',
  },
  {
    name:                 'Agent Chaosu',
    discount:             2,
    story_description:    'Rekrut zrobił coś „po króliczemu”',
    didactic_description: 'Zdobyte co najmniej 3 marchewki za ciekawą uwagę',
  },
  {
    name:                 'Królik Drużynowy',
    discount:             3,
    story_description:    'Królik uratował załogę',
    didactic_description: 'Wyjaśnienie jakiegoś trudnego zagadnienia/zadania całej grupie',
  },
].freeze

BADGES.each do |badge_data|
  Badge.create!(story_group: story_group, **badge_data)
end

ITEMS_DATA = [
  {
    name:                  '0.5% oceny',
    story_description:     'Najwyższa Rada Królików przyznaje specjalną nagrodę za szczególne zasługi',
    didactic_description:  'Podniesienie oceny POZYTYWNEJ o pół stopnia',
    min_rank_for_discount: story_group.ranks.find_by!(name: 'Mistrz Marchewki'),
    unlock_rank:           story_group.ranks.find_by!(name: 'Strateg Imperium'),
    unlock_badges:         [story_group.badges.find_by!(name: 'Zawsze na pokładzie')],
    price:                 80,
  },
  {
    name:                  '+3% do oceny',
    story_description:     'Wielka Marchewka dodaje królikowi punktów mocy',
    didactic_description:  '+3 punkty procentowe do ogólnego wyniku studenta/studentki',
    price:                 80,
    unlock_rank:           story_group.ranks.find_by!(name: 'Pilot Marcheton-7'),
    min_rank_for_discount: story_group.ranks.find_by!(name: 'Strateg Imperium'),
  },
  {
    name:                 'Zaliczenie wejściówki',
    story_description:    'Statek wrócił z misji uszkodzony, ale wrócił',
    didactic_description: 'Zaliczenie słabo napisanej wejściówki na 50%',
    price:                35,
  },
  {
    name:                 '+10% do wejściówki',
    story_description:    'Wsparcie dowództwa królików',
    didactic_description: '+10 punktów procentowych do wejściówki (do maksymalnie 100% w wyniku)',
    price:                33,
  },
  {
    name:                 '+5% do wejściówki',
    story_description:    'Flota dosyła dodatkowe zapasy',
    didactic_description: '+5 punktów procentowych do wejściówki (do maksymalnie 100% w wyniku)',
    price:                30,
  },
  {
    name:                 '+5 minut do wejściówki',
    story_description:    'Spowolnienie czasu w nadprzestrzeni',
    didactic_description: 'Dodatkowe 5 minut na wejściówce',
    price:                15,
  },
  {
    name:                 'Konsultacja',
    story_description:    'Konsultacja z Mistrzem Królików',
    didactic_description: 'Możliwość zadania pytania (nie wprost o prawidłową odpowiedź) ' \
                          'prowadzącego podczas wejściówki',
    price:                15,
  },
  {
    name:                 'Poprawa wejściówki',
    story_description:    'Awaryjny powrót statku do bazy',
    didactic_description: 'Możliwość ponownego napisania (poprawy) wejściówki',
    price:                15,
  },
  {
    name:                 'Bezpieczna poprawa',
    story_description:    'Statek trafia do hangaru ochronnego',
    didactic_description: 'Możliwość ponownego napisania (poprawy) wejściówki z zamrożeniem ' \
                          'obecnego wyniku (czyli nie można pogorszyć wyniku)',
    price:                20,
  },
  {
    name:                  'Poprawa trzech wejściówek',
    story_description:     'W statku trzeba naprawić kilka modułów',
    didactic_description:  'Możliwość ponownego napisania (poprawy) trzech wybranych wejściówek',
    price:                 40,
    unlock_rank:           story_group.ranks.find_by!(name: 'Kosmiczny Królik'),
    min_rank_for_discount: story_group.ranks.find_by!(name: 'Pilot Marcheton-7'),
  },
  {
    name:                  'Bezpieczna poprawa trzech wejściówek',
    story_description:     'W statku trzeba naprawić kilka modułów i na ten czas królik ' \
                           'otrzymuje statek zastępczy',
    didactic_description:  'Możliwość ponownego napisania (poprawy) trzech wybranych z ' \
                           'zamrożeniem obecnego wyniku (czyli nie można pogorszyć wyniku)',
    price:                 50,
    unlock_rank:           story_group.ranks.find_by!(name: 'Kosmiczny Królik'),
    min_rank_for_discount: story_group.ranks.find_by!(name: 'Pilot Marcheton-7'),
  },
  {
    name:                  'Spóźnienie',
    story_description:     'Teleporter działał z opóźnieniem',
    didactic_description:  'Jedno spóźnienie bez straty marchewek za punktualność',
    price:                 5,
    unlock_rank:           story_group.ranks.find_by!(name: 'Kosmiczny Królik'),
    min_rank_for_discount: story_group.ranks.find_by!(name: 'Pilot Marcheton-7'),
  },
  {
    name:                  'Usprawiedliwienie',
    story_description:     'Misja zdalna dla floty',
    didactic_description:  'Jedna usprawiedliwiona nieobecność bez straty marchewek za obecność i punktualność',
    price:                 10,
    unlock_rank:           story_group.ranks.find_by!(name: 'Kosmiczny Królik'),
    min_rank_for_discount: story_group.ranks.find_by!(name: 'Pilot Marcheton-7'),
  },
  {
    name:                  '1up',
    story_description:     'Reanimacja królika',
    didactic_description:  'Odzzyskanie jednego życia w ramach grywalizacji - kontynuacja gry',
    price:                 50,
    min_rank_for_discount: story_group.ranks.find_by!(name: 'Mistrz Marchewki'),
    can_buy_at_0_lives:    true,
  },
].freeze

ITEMS_DATA.each do |item_data|
  Item.create!(story_group: story_group, **item_data)
end

LABORATORIES_CATEGORIES = [
  {
    story_description:    'Rekrut stawił się na zbiórce floty króliczej i nie zgubił się w nadprzestrzeni.',
    didactic_description: 'Punktualny/a',
    reward:               2,
  },
  {
    story_description:    'Rekrut dotarł po starcie statku, ale doleciał.',
    didactic_description: 'Obecny/a',
    reward:               2,
  },
  {
    story_description:    'Misja zakończona sukcesem – statek wrócił do bazy.',
    didactic_description: 'Wejściówka zaliczona',
    reward:               1,
  },
  {
    story_description:    'Rekrut wykonał zadanie zgodnie z normami floty.',
    didactic_description: 'Wejściówka na poziomie co najmniej średniej grupy',
    reward:               1,
  },
  {
    story_description:    'Misja wykonana perfekcyjnie – bez strat i uszkodzeń statku.',
    didactic_description: 'Wejściówka na maxa',
    reward:               2,
  },
  {
    story_description:    'Rekrut zgłosił się do wykonania misji pomocniczej na statku.',
    didactic_description: 'Zgłoszenie się do zrobienia zadania',
    reward:               1,
  },
  {
    story_description:    'Rekrut samodzielnie naprawił zepsuty moduł statku — statek może lecieć dalej.',
    didactic_description: 'Samodzielnie i poprawnie zrobione zadanie',
    reward:               1,
  },
  {
    story_description:    'Rekrut uratował innego królika przed dryfowaniem w próżni.',
    didactic_description: 'Pomoc innym',
    reward:               1,
  },
  {
    story_description:    'Rekrut odkrył nieznane zjawisko kosmiczne.',
    didactic_description: 'Ciekawa uwaga',
    reward:               1,
  },
  {
    story_description:    'Rekrut udzielał się w naradzie załogi.',
    didactic_description: 'Udział w dyskusji',
    reward:               1,
  },
  {
    story_description:    'Rekrut przedstawił raport z obserwacji podczas misji.',
    didactic_description: 'Odpowiedź na pytanie wiedzy prowadzącego',
    reward:               1,
  },
].freeze

SUMMARY_CATEGORIES = [
  {
    story_description:    'Rekrut nie opuścił ani jednej misji',
    didactic_description: 'Punktualny/a zawsze',
    reward:               3,
  },
  {
    story_description:    'Rekrut prawie zawsze był na posterunku',
    didactic_description: 'Obecny/a i prawie zawsze punktualny/a (1 spóźnienie)',
    reward:               2,
  },
  {
    story_description:    'Flota działała bez przerw',
    didactic_description: 'Wszystkie wejściówki zaliczone',
    reward:               2,
  },
  {
    story_description:    'Rekrut trzymał wysoki poziom misji',
    didactic_description: 'Wszystkie wejściówki >= średnia grupy',
    reward:               3,
  },
  {
    story_description:    'Co najmniej jedna misja wykonana idealnie',
    didactic_description: 'Co najmniej jedna wejściówka bez błędów',
    reward:               1,
  },
  {
    story_description:    'Miesiąc perfekcyjnych lotów',
    didactic_description: 'Wszystkie wejściówki bez błędów',
    reward:               4,
  },
].freeze

labs = ActivityGroupTemplate.create!(base_name: 'Laboratoria', story_group: story_group)
summaries = ActivityGroupTemplate.create!(base_name: 'Podsumowanie', story_group: story_group)

LABORATORIES_CATEGORIES.each do |data|
  ActivityGroupTemplateCategory.create!(activity_group_template: labs, **data)
end

SUMMARY_CATEGORIES.each do |data|
  ActivityGroupTemplateCategory.create!(activity_group_template: summaries, **data)
end
