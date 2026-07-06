/// Central registry of every image / icon / logo path used by the app.
///
/// Assets are loaded by these paths from `assets/…`. Files are provided
/// progressively by the design team; until a file exists the loader widgets
/// ([AppAssetImage] / [AppSvgIcon]) render nothing (never a substitute icon or
/// emoji). Dropping the real file with the matching name makes it appear
/// automatically — no code change required.
abstract class AppAssets {
  AppAssets._();

  static const String _logo = 'assets/logo';
  static const String _icons = 'assets/icons';
  static const String _categoryIcons = 'assets/category-icons';
  static const String _products = 'assets/products';
  static const String _backgrounds = 'assets/backgrounds';
  static const String _illustrations = 'assets/illustrations';

  // ── Logo ────────────────────────────────────────────────────────────────
  static const String logoSvg = '$_logo/logo.svg';
  static const String logoGold = '$_logo/logo-gold.svg';
  static const String logoWhite = '$_logo/logo-white.svg';
  static const String logoBlack = '$_logo/logo-black.svg';
  static const String logoPng = '$_logo/logo.png';
  static const String splashLogo = '$_logo/splash-logo.png';

  // ── UI icons (golden outline set) ─────────────────────────────────────────
  static const String iconHome = '$_icons/home.svg';
  static const String iconCategories = '$_icons/categories.svg';
  static const String iconOffers = '$_icons/offers.svg';
  static const String iconCart = '$_icons/cart.svg';
  static const String iconOrders = '$_icons/orders.svg';
  static const String iconProfile = '$_icons/profile.svg';
  static const String iconSearch = '$_icons/search.svg';
  static const String iconNotification = '$_icons/notification.svg';
  static const String iconSettings = '$_icons/settings.svg';
  static const String iconHeart = '$_icons/heart.svg';
  static const String iconLocation = '$_icons/location.svg';
  static const String iconDelivery = '$_icons/delivery.svg';
  static const String iconTruck = '$_icons/truck.svg';
  static const String iconPayment = '$_icons/payment.svg';
  static const String iconWallet = '$_icons/wallet.svg';
  static const String iconSupport = '$_icons/support.svg';
  static const String iconPhone = '$_icons/phone.svg';
  static const String iconChat = '$_icons/chat.svg';
  static const String iconMail = '$_icons/mail.svg';
  static const String iconLogout = '$_icons/logout.svg';
  static const String iconPlus = '$_icons/plus.svg';
  static const String iconMinus = '$_icons/minus.svg';
  static const String iconStar = '$_icons/star.svg';
  static const String iconFilter = '$_icons/filter.svg';
  static const String iconSort = '$_icons/sort.svg';
  static const String iconArrowLeft = '$_icons/arrow-left.svg';
  static const String iconArrowRight = '$_icons/arrow-right.svg';
  static const String iconCheck = '$_icons/check.svg';
  static const String iconClose = '$_icons/close.svg';
  static const String iconMenu = '$_icons/menu.svg';

  // ── Backgrounds & illustrations ───────────────────────────────────────────
  static const String heroBasket = '$_backgrounds/hero-basket.png';
  static const String splashBg = '$_backgrounds/splash-bg.png';
  static const String storeBuilding = '$_illustrations/store-building.png';
  static const String deliveryTruck = '$_illustrations/delivery-truck.png';
  static const String deliveryHero = '$_illustrations/delivery-hero.png';

  /// Category tile image, keyed by the backend category `slug`.
  /// e.g. slug `canned-goods` → `assets/category-icons/canned-goods.png`.
  static String categoryIcon(String slug) => '$_categoryIcons/$slug.png';

  /// Product image, keyed by product `id` or `sku`.
  static String product(String key) => '$_products/$key.png';
}
