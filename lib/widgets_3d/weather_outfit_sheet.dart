import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sound_service.dart';
import '../theme/stationery_theme.dart';
import 'bouncy_tap.dart';

/// ---------------------------------------------------------------------------
/// WEATHER SEASON, OUTFIT ADVISOR & INTERACTIVE HOVER PAGE
/// - Determines active season (Spring, Summer, Autumn, Winter) with vector icon
/// - Computes full wear & carry recommendations from live weather + AQI + season
/// - Renders the authentic Tooler vector character dynamically dressed in cap,
///   sweater/shirt/t-shirt/raincoat, pant/shorts, boots/shoes/slippers, gloves,
///   mask, oxygen cylinder, umbrella, and seasonal tools
/// - Interactive preset switcher (Live, Summer, Winter, Autumn, Spring, Rainy,
///   Snow, High AQI) inside a spring-animated floating hover page
/// ---------------------------------------------------------------------------

enum WeatherSeason {
  spring,
  summer,
  autumn,
  winter,
}

extension WeatherSeasonInfo on WeatherSeason {
  String get label {
    switch (this) {
      case WeatherSeason.spring:
        return 'Spring';
      case WeatherSeason.summer:
        return 'Summer';
      case WeatherSeason.autumn:
        return 'Autumn';
      case WeatherSeason.winter:
        return 'Winter';
    }
  }

  IconData get icon {
    switch (this) {
      case WeatherSeason.spring:
        return Icons.local_florist_rounded;
      case WeatherSeason.summer:
        return Icons.wb_sunny_rounded;
      case WeatherSeason.autumn:
        return Icons.eco_rounded;
      case WeatherSeason.winter:
        return Icons.ac_unit_rounded;
    }
  }

  Color get color {
    switch (this) {
      case WeatherSeason.spring:
        return const Color(0xFF10B981);
      case WeatherSeason.summer:
        return const Color(0xFFF59E0B);
      case WeatherSeason.autumn:
        return const Color(0xFFF97316);
      case WeatherSeason.winter:
        return const Color(0xFF38BDF8);
    }
  }
}

enum OutfitPresetMode {
  live,
  summer,
  winter,
  autumn,
  spring,
  rainy,
  snow,
  highAqi,
}

extension OutfitPresetModeInfo on OutfitPresetMode {
  String get label {
    switch (this) {
      case OutfitPresetMode.live:
        return 'Live Now';
      case OutfitPresetMode.summer:
        return 'Summer';
      case OutfitPresetMode.winter:
        return 'Winter';
      case OutfitPresetMode.autumn:
        return 'Autumn';
      case OutfitPresetMode.spring:
        return 'Spring';
      case OutfitPresetMode.rainy:
        return 'Rainy';
      case OutfitPresetMode.snow:
        return 'Snow';
      case OutfitPresetMode.highAqi:
        return 'High AQI';
    }
  }

  IconData get icon {
    switch (this) {
      case OutfitPresetMode.live:
        return Icons.sensors_rounded;
      case OutfitPresetMode.summer:
        return Icons.wb_sunny_rounded;
      case OutfitPresetMode.winter:
        return Icons.severe_cold_rounded;
      case OutfitPresetMode.autumn:
        return Icons.eco_rounded;
      case OutfitPresetMode.spring:
        return Icons.local_florist_rounded;
      case OutfitPresetMode.rainy:
        return Icons.umbrella_rounded;
      case OutfitPresetMode.snow:
        return Icons.ac_unit_rounded;
      case OutfitPresetMode.highAqi:
        return Icons.masks_rounded;
    }
  }
}

enum CapStyle { none, baseballCap, woolBeanie, rainHood, sunBucketHat }

enum TopStyle { tShirt, casualShirt, sweater, pufferJacket, raincoat }

enum PantStyle { shorts, chinosJeans, quickDryJoggers, thermalSnowPants }

enum FootwearStyle { slippers, sneakers, rainBoots, snowBoots }

class WeatherOutfitContext {
  final double tempC;
  final String condition;
  final bool isDay;
  final bool isRain;
  final bool isThunder;
  final bool isCloudy;
  final bool isSnow;
  final int aqi;
  final double humidity;
  final double windSpeedKmH;
  final double uvIndex;
  final WeatherSeason season;
  final String city;

  const WeatherOutfitContext({
    required this.tempC,
    required this.condition,
    required this.isDay,
    required this.isRain,
    required this.isThunder,
    required this.isCloudy,
    required this.isSnow,
    required this.aqi,
    required this.humidity,
    required this.windSpeedKmH,
    required this.uvIndex,
    required this.season,
    required this.city,
  });

  WeatherOutfitContext forPreset(OutfitPresetMode mode) {
    switch (mode) {
      case OutfitPresetMode.live:
        return this;
      case OutfitPresetMode.summer:
        return const WeatherOutfitContext(
          tempC: 37.0,
          condition: 'Hot Sunny Summer',
          isDay: true,
          isRain: false,
          isThunder: false,
          isCloudy: false,
          isSnow: false,
          aqi: 48,
          humidity: 36,
          windSpeedKmH: 8,
          uvIndex: 9.2,
          season: WeatherSeason.summer,
          city: 'Summer Preset',
        );
      case OutfitPresetMode.winter:
        return const WeatherOutfitContext(
          tempC: 7.0,
          condition: 'Crisp Cold Winter',
          isDay: true,
          isRain: false,
          isThunder: false,
          isCloudy: false,
          isSnow: false,
          aqi: 68,
          humidity: 44,
          windSpeedKmH: 15,
          uvIndex: 2.0,
          season: WeatherSeason.winter,
          city: 'Winter Preset',
        );
      case OutfitPresetMode.autumn:
        return const WeatherOutfitContext(
          tempC: 18.0,
          condition: 'Breezy Autumn',
          isDay: true,
          isRain: false,
          isThunder: false,
          isCloudy: true,
          isSnow: false,
          aqi: 82,
          humidity: 54,
          windSpeedKmH: 19,
          uvIndex: 4.0,
          season: WeatherSeason.autumn,
          city: 'Autumn Preset',
        );
      case OutfitPresetMode.spring:
        return const WeatherOutfitContext(
          tempC: 23.0,
          condition: 'Mild Spring Breeze',
          isDay: true,
          isRain: false,
          isThunder: false,
          isCloudy: false,
          isSnow: false,
          aqi: 42,
          humidity: 50,
          windSpeedKmH: 11,
          uvIndex: 5.5,
          season: WeatherSeason.spring,
          city: 'Spring Preset',
        );
      case OutfitPresetMode.rainy:
        return const WeatherOutfitContext(
          tempC: 20.0,
          condition: 'Heavy Rain & Wind',
          isDay: false,
          isRain: true,
          isThunder: true,
          isCloudy: true,
          isSnow: false,
          aqi: 38,
          humidity: 91,
          windSpeedKmH: 22,
          uvIndex: 1.0,
          season: WeatherSeason.autumn,
          city: 'Rainy Preset',
        );
      case OutfitPresetMode.snow:
        return const WeatherOutfitContext(
          tempC: -4.0,
          condition: 'Heavy Snowfall',
          isDay: true,
          isRain: false,
          isThunder: false,
          isCloudy: true,
          isSnow: true,
          aqi: 32,
          humidity: 78,
          windSpeedKmH: 20,
          uvIndex: 1.5,
          season: WeatherSeason.winter,
          city: 'Snow Preset',
        );
      case OutfitPresetMode.highAqi:
        return const WeatherOutfitContext(
          tempC: 27.0,
          condition: 'Severe Smog Alert',
          isDay: true,
          isRain: false,
          isThunder: false,
          isCloudy: true,
          isSnow: false,
          aqi: 285,
          humidity: 60,
          windSpeedKmH: 4,
          uvIndex: 3.5,
          season: WeatherSeason.autumn,
          city: 'Smog Alert Preset',
        );
    }
  }
}

class GearToolItem {
  final String name;
  final String detail;
  final IconData icon;
  final Color color;

  const GearToolItem({
    required this.name,
    required this.detail,
    required this.icon,
    required this.color,
  });
}

class SeasonalKitSection {
  final String title;
  final IconData icon;
  final Color color;
  final List<GearToolItem> items;

  const SeasonalKitSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });
}

class OutfitRecommendation {
  final CapStyle capStyle;
  final String capType;
  final String capDetail;

  final TopStyle topStyle;
  final String sweaterType;
  final String sweaterDetail;
  final String shirtType;
  final String shirtDetail;

  final PantStyle pantStyle;
  final String pantType;
  final String pantDetail;

  final FootwearStyle footwearStyle;
  final String footwearType;
  final String footwearDetail;

  final bool hasGloves;
  final String glovesType;
  final String glovesDetail;

  final bool hasRaincoat;
  final String raincoatStatus;
  final String raincoatDetail;

  final bool hasUmbrella;
  final String umbrellaStatus;
  final String umbrellaDetail;

  final bool hasMask;
  final String maskStatus;
  final String maskDetail;

  final bool hasOxygenCylinder;
  final String oxygenStatus;
  final String oxygenDetail;

  final bool hasSunglasses;
  final String activeToolsTitle;
  final List<GearToolItem> activeTools;
  final List<SeasonalKitSection> allSeasonalKits;

  const OutfitRecommendation({
    required this.capStyle,
    required this.capType,
    required this.capDetail,
    required this.topStyle,
    required this.sweaterType,
    required this.sweaterDetail,
    required this.shirtType,
    required this.shirtDetail,
    required this.pantStyle,
    required this.pantType,
    required this.pantDetail,
    required this.footwearStyle,
    required this.footwearType,
    required this.footwearDetail,
    required this.hasGloves,
    required this.glovesType,
    required this.glovesDetail,
    required this.hasRaincoat,
    required this.raincoatStatus,
    required this.raincoatDetail,
    required this.hasUmbrella,
    required this.umbrellaStatus,
    required this.umbrellaDetail,
    required this.hasMask,
    required this.maskStatus,
    required this.maskDetail,
    required this.hasOxygenCylinder,
    required this.oxygenStatus,
    required this.oxygenDetail,
    required this.hasSunglasses,
    required this.activeToolsTitle,
    required this.activeTools,
    required this.allSeasonalKits,
  });

  static OutfitRecommendation compute(WeatherOutfitContext ctx) {
    final bool isFreezing = ctx.isSnow || ctx.tempC <= 8.0;
    final bool isCold = ctx.tempC > 8.0 && ctx.tempC <= 16.0;
    final bool isCool = ctx.tempC > 16.0 && ctx.tempC <= 22.0;
    final bool isHot = ctx.tempC >= 30.0;

    // 1. Cap / Headwear
    final CapStyle capStyle;
    final String capType;
    final String capDetail;
    if (ctx.isSnow || isFreezing) {
      capStyle = CapStyle.woolBeanie;
      capType = 'Wool Knit Beanie';
      capDetail = 'Insulated fleece-lined beanie to lock in warmth';
    } else if (ctx.isRain || ctx.isThunder) {
      capStyle = CapStyle.rainHood;
      capType = 'Waterproof Rain Cap / Hood';
      capDetail = 'Keeps rain off face & hair during downpours';
    } else if (isHot || (ctx.isDay && ctx.uvIndex >= 6.0)) {
      capStyle = CapStyle.baseballCap;
      capType = 'Breathable Sun Cap';
      capDetail = 'UV-shielding cotton baseball or bucket cap';
    } else if (ctx.season == WeatherSeason.autumn || isCold) {
      capStyle = CapStyle.baseballCap;
      capType = 'Light Cotton Cap';
      capDetail = 'Blocks crisp wind & mild afternoon glare';
    } else {
      capStyle = CapStyle.none;
      capType = 'Optional Light Cap';
      capDetail = 'Mild sky — cap only if outdoors at noon';
    }

    // 2. Sweater / Jacket + Shirt / T-Shirt + Raincoat
    final bool hasRaincoat = ctx.isRain || ctx.isThunder;
    final TopStyle topStyle;
    final String sweaterType;
    final String sweaterDetail;
    final String shirtType;
    final String shirtDetail;

    if (ctx.isSnow || ctx.tempC <= 5.0) {
      topStyle = hasRaincoat ? TopStyle.raincoat : TopStyle.pufferJacket;
      sweaterType = 'Heavy Puffer + Wool Sweater';
      sweaterDetail = 'Thick insulated jacket layered over knit wool';
      shirtType = 'Thermal Full-Sleeve Shirt';
      shirtDetail = 'Heat-retaining cotton/merino base layer';
    } else if (isFreezing || isCold) {
      topStyle = hasRaincoat ? TopStyle.raincoat : TopStyle.sweater;
      sweaterType = 'Cozy Knit Sweater';
      sweaterDetail = 'Warm pullover or fleece cardigan for cold air';
      shirtType = 'Full-Sleeve Casual Shirt';
      shirtDetail = 'Layered button-up shirt or thermal tee';
    } else if (hasRaincoat) {
      topStyle = TopStyle.raincoat;
      sweaterType = isCool ? 'Light Fleece Undercoat' : 'No Heavy Sweater';
      sweaterDetail = isCool ? 'Thin layer beneath waterproof shell' : 'Keep layers light under raincoat';
      shirtType = 'Quick-Dry T-Shirt';
      shirtDetail = 'Moisture-wicking tee dries fast in damp air';
    } else if (isCool || ctx.season == WeatherSeason.autumn) {
      topStyle = TopStyle.casualShirt;
      sweaterType = 'Light Cardigan / Windcheater';
      sweaterDetail = 'Easy-to-remove sweater for cool evening breeze';
      shirtType = 'Flannel or Cotton Shirt';
      shirtDetail = 'Comfortable long-sleeve or rolled-cuff shirt';
    } else {
      topStyle = TopStyle.tShirt;
      sweaterType = 'No Sweater Needed';
      sweaterDetail = 'Too warm for woolens — stick to airy single layer';
      shirtType = isHot ? 'Loose Cotton / Sleeveless Tee' : 'Breathable Cotton T-Shirt';
      shirtDetail = 'Light-colored sweat-wicking fabric keeps you cool';
    }

    // 3. Pant Type
    final PantStyle pantStyle;
    final String pantType;
    final String pantDetail;
    if (ctx.isSnow || ctx.tempC <= 5.0) {
      pantStyle = PantStyle.thermalSnowPants;
      pantType = 'Thermal / Snow Pants';
      pantDetail = 'Water-repellent fleece-lined winter trousers';
    } else if (ctx.isRain || ctx.isThunder) {
      pantStyle = PantStyle.quickDryJoggers;
      pantType = 'Quick-Dry Ankle Joggers';
      pantDetail = 'Tapered cuffs prevent puddle splashes & dry fast';
    } else if (isHot && !ctx.isCloudy) {
      pantStyle = PantStyle.shorts;
      pantType = 'Airy Shorts / Linen Pants';
      pantDetail = 'Maximum airflow to beat peak daytime heat';
    } else if (isCold || ctx.season == WeatherSeason.winter || ctx.season == WeatherSeason.autumn) {
      pantStyle = PantStyle.chinosJeans;
      pantType = 'Denim Jeans / Heavy Chinos';
      pantDetail = 'Wind-blocking sturdy cotton pants';
    } else {
      pantStyle = PantStyle.chinosJeans;
      pantType = 'Light Cotton Chinos / Jeans';
      pantDetail = 'Balanced comfort for mild spring/breezy day';
    }

    // 4. Footwear (Boots / Shoes / Slippers)
    final FootwearStyle footwearStyle;
    final String footwearType;
    final String footwearDetail;
    if (ctx.isSnow || ctx.tempC <= 3.0) {
      footwearStyle = FootwearStyle.snowBoots;
      footwearType = 'Insulated Snow Boots';
      footwearDetail = 'High-grip lug soles + warm fur/thermal lining';
    } else if (ctx.isRain || ctx.isThunder) {
      footwearStyle = FootwearStyle.rainBoots;
      footwearType = 'Waterproof Rain Boots';
      footwearDetail = 'Non-slip rubber boots (avoid open slippers in mud)';
    } else if (isHot && !ctx.isCloudy) {
      footwearStyle = FootwearStyle.slippers;
      footwearType = 'Open Slippers / Breathable Sandals';
      footwearDetail = 'Keeps feet sweat-free (or light canvas shoes)';
    } else {
      footwearStyle = FootwearStyle.sneakers;
      footwearType = 'Cushioned Sneakers / Shoes';
      footwearDetail = 'Closed breathable walking shoes with ankle socks';
    }

    // 5. Gloves
    final bool hasGloves = ctx.isSnow || ctx.tempC <= 10.0 || (ctx.season == WeatherSeason.winter && ctx.windSpeedKmH >= 15);
    final String glovesType = ctx.isSnow
        ? 'Waterproof Snow Gloves'
        : (hasGloves ? 'Insulated Knit Gloves' : 'No Gloves Needed');
    final String glovesDetail = ctx.isSnow
        ? 'Thermal touchscreen-tip ski/snow gloves'
        : (hasGloves ? 'Protects hands from cold windchill' : 'Temperature is warm enough for bare hands');

    // 6. Raincoat
    final String raincoatStatus = hasRaincoat ? 'Wear Raincoat' : (ctx.isCloudy ? 'Pack Light Poncho' : 'Not Needed');
    final String raincoatDetail = hasRaincoat
        ? 'Waterproof hooded shell or trench over clothes'
        : (ctx.isCloudy ? 'Handy foldable pocket raincoat if clouds thicken' : 'Clear forecast — leave raincoat at home');

    // 7. Umbrella
    final bool rainUmbrella = ctx.isRain || ctx.isThunder;
    final bool uvUmbrella = !rainUmbrella && ctx.isDay && ctx.uvIndex >= 7.5 && ctx.tempC >= 32.0;
    final bool hasUmbrella = rainUmbrella || uvUmbrella;
    final String umbrellaStatus = rainUmbrella
        ? (ctx.isThunder ? 'Windproof Umbrella' : 'Carry Umbrella')
        : (uvUmbrella ? 'UV Sun Umbrella' : 'Not Required');
    final String umbrellaDetail = rainUmbrella
        ? (ctx.isThunder ? 'Sturdy vented canopy (avoid metal tips outdoors)' : 'Full coverage against steady rain showers')
        : (uvUmbrella ? 'Reflective UV umbrella shields direct midday sun' : 'Low rain & moderate UV right now');

    // 8. Mask
    final bool hasMask = ctx.aqi > 100 || (ctx.isSnow && ctx.windSpeedKmH > 18) || (ctx.aqi > 75 && ctx.season == WeatherSeason.autumn);
    final String maskStatus;
    final String maskDetail;
    if (ctx.aqi > 200) {
      maskStatus = 'Mandatory N95 / N99 Mask';
      maskDetail = 'Severe particulate pollution (AQI ${ctx.aqi}) — seal tightly';
    } else if (ctx.aqi > 100) {
      maskStatus = 'Wear N95 Mask';
      maskDetail = 'Filters fine PM2.5 dust & smog (AQI ${ctx.aqi})';
    } else if (ctx.isSnow && ctx.windSpeedKmH > 18) {
      maskStatus = 'Thermal Face Gaiter';
      maskDetail = 'Warms inhaled icy air & blocks windburn';
    } else if (ctx.aqi > 50) {
      maskStatus = 'Optional Pollen / Dust Mask';
      maskDetail = 'Helpful for sensitive lungs or high pollen';
    } else {
      maskStatus = 'Not Needed (Clean Air)';
      maskDetail = 'Air quality is fresh (AQI ${ctx.aqi})';
    }

    // 9. Oxygen Cylinder
    final bool hasOxygenCylinder = ctx.aqi > 200;
    final String oxygenStatus = hasOxygenCylinder
        ? 'Carry Portable O₂ Cylinder'
        : (ctx.aqi > 150 ? 'Keep O₂ Standby (Sensitive)' : 'Not Required');
    final String oxygenDetail = hasOxygenCylinder
        ? 'Hazardous AQI (${ctx.aqi}) — keep emergency O₂ canister + mask ready'
        : (ctx.aqi > 150
            ? 'Recommended standby for asthma/respiratory patients'
            : 'Ambient oxygen & air quality are safe');

    final bool hasSunglasses = ctx.isDay && (isHot || ctx.uvIndex >= 5.0 || ctx.isSnow);

    // 10. Seasonal & Weather Tools Kits
    const snowTools = SeasonalKitSection(
      title: 'Snow Tools & Kit',
      icon: Icons.ac_unit_rounded,
      color: Color(0xFF38BDF8),
      items: [
        GearToolItem(name: 'Snow Shovel', detail: 'Clear paths & steps', icon: Icons.construction_rounded, color: Color(0xFF0EA5E9)),
        GearToolItem(name: 'Ice Scraper & Grips', detail: 'Boot crampons & windshield scraper', icon: Icons.hardware_rounded, color: Color(0xFF38BDF8)),
        GearToolItem(name: 'Anti-Fog Goggles', detail: 'Block snow glare & sleet', icon: Icons.visibility_rounded, color: Color(0xFF6366F1)),
        GearToolItem(name: 'Hand Warmers', detail: 'Pocket heat packs + thermos', icon: Icons.whatshot_rounded, color: Color(0xFFF97316)),
      ],
    );

    const summerTools = SeasonalKitSection(
      title: 'Summer Tools & Essentials',
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFF59E0B),
      items: [
        GearToolItem(name: 'SPF 50+ Sunscreen', detail: 'Reapply every 2 hours', icon: Icons.spa_rounded, color: Color(0xFFF59E0B)),
        GearToolItem(name: 'Polarized Sunglasses', detail: 'UV400 eye shield', icon: Icons.dark_mode_rounded, color: Color(0xFFFB923C)),
        GearToolItem(name: 'Insulated Water Bottle', detail: 'Electrolytes + cold hydration', icon: Icons.water_drop_rounded, color: Color(0xFF0EA5E9)),
        GearToolItem(name: 'Cooling Towel / Mini Fan', detail: 'Instant heat relief outdoors', icon: Icons.air_rounded, color: Color(0xFF10B981)),
      ],
    );

    const winterTools = SeasonalKitSection(
      title: 'Winter Tools & Layering',
      icon: Icons.severe_cold_rounded,
      color: Color(0xFF60A5FA),
      items: [
        GearToolItem(name: 'Thermos Hot Flask', detail: 'Warm tea, soup or water', icon: Icons.local_cafe_rounded, color: Color(0xFFF97316)),
        GearToolItem(name: 'Wool Scarf & Socks', detail: 'Neck muffler + thermal socks', icon: Icons.checkroom_rounded, color: Color(0xFF38BDF8)),
        GearToolItem(name: 'Lip Balm & Cream', detail: 'Prevent cold-air chapping', icon: Icons.healing_rounded, color: Color(0xFFEC4899)),
        GearToolItem(name: 'Pocket Hand Warmers', detail: 'Keep fingers warm outside', icon: Icons.whatshot_rounded, color: Color(0xFFEF4444)),
      ],
    );

    const autumnTools = SeasonalKitSection(
      title: 'Autumn Tools & Clothes',
      icon: Icons.eco_rounded,
      color: Color(0xFFF97316),
      items: [
        GearToolItem(name: 'Flannel & Trench Layer', detail: 'Wind-blocking mid layer + scarf', icon: Icons.checkroom_rounded, color: Color(0xFFF97316)),
        GearToolItem(name: 'Compact Umbrella', detail: 'For sudden autumn drizzles', icon: Icons.umbrella_rounded, color: Color(0xFF0284C7)),
        GearToolItem(name: 'Anti-Allergy Tissues', detail: 'Pollen & dry-leaf dust relief', icon: Icons.medical_services_rounded, color: Color(0xFF10B981)),
        GearToolItem(name: 'Ankle Boots & Mist', detail: 'Sturdy shoes + skin moisturizer', icon: Icons.hiking_rounded, color: Color(0xFFD97706)),
      ],
    );

    const springTools = SeasonalKitSection(
      title: 'Spring Tools & Clothes',
      icon: Icons.local_florist_rounded,
      color: Color(0xFF10B981),
      items: [
        GearToolItem(name: 'Light Denim Jacket', detail: 'Easy layer for breezy mornings', icon: Icons.checkroom_rounded, color: Color(0xFF10B981)),
        GearToolItem(name: 'Pollen Filter Mask', detail: 'Blocks spring bloom allergens', icon: Icons.masks_rounded, color: Color(0xFF059669)),
        GearToolItem(name: 'Compact Rain Shell', detail: 'Quick cover for spring showers', icon: Icons.umbrella_rounded, color: Color(0xFF0284C7)),
        GearToolItem(name: 'Hydration & Eye Drops', detail: 'Stay fresh on walks & rides', icon: Icons.water_drop_rounded, color: Color(0xFF38BDF8)),
      ],
    );

    final SeasonalKitSection primaryKit;
    if (ctx.isSnow) {
      primaryKit = snowTools;
    } else if (ctx.season == WeatherSeason.summer || isHot) {
      primaryKit = summerTools;
    } else if (ctx.season == WeatherSeason.winter || isFreezing) {
      primaryKit = winterTools;
    } else if (ctx.season == WeatherSeason.autumn) {
      primaryKit = autumnTools;
    } else {
      primaryKit = springTools;
    }

    final allKits = <SeasonalKitSection>[
      primaryKit,
      if (primaryKit.title != snowTools.title) snowTools,
      if (primaryKit.title != summerTools.title) summerTools,
      if (primaryKit.title != winterTools.title) winterTools,
      if (primaryKit.title != autumnTools.title) autumnTools,
      if (primaryKit.title != springTools.title) springTools,
    ];

    return OutfitRecommendation(
      capStyle: capStyle,
      capType: capType,
      capDetail: capDetail,
      topStyle: topStyle,
      sweaterType: sweaterType,
      sweaterDetail: sweaterDetail,
      shirtType: shirtType,
      shirtDetail: shirtDetail,
      pantStyle: pantStyle,
      pantType: pantType,
      pantDetail: pantDetail,
      footwearStyle: footwearStyle,
      footwearType: footwearType,
      footwearDetail: footwearDetail,
      hasGloves: hasGloves,
      glovesType: glovesType,
      glovesDetail: glovesDetail,
      hasRaincoat: hasRaincoat,
      raincoatStatus: raincoatStatus,
      raincoatDetail: raincoatDetail,
      hasUmbrella: hasUmbrella,
      umbrellaStatus: umbrellaStatus,
      umbrellaDetail: umbrellaDetail,
      hasMask: hasMask,
      maskStatus: maskStatus,
      maskDetail: maskDetail,
      hasOxygenCylinder: hasOxygenCylinder,
      oxygenStatus: oxygenStatus,
      oxygenDetail: oxygenDetail,
      hasSunglasses: hasSunglasses,
      activeToolsTitle: primaryKit.title,
      activeTools: primaryKit.items,
      allSeasonalKits: allKits,
    );
  }
}

/// ---------------------------------------------------------------------------
/// LAUNCHER FOR THE FLOATING SPRING-ANIMATED "WHAT TO WEAR & CARRY" HOVER PAGE
/// ---------------------------------------------------------------------------
Future<void> showWhatToWearHoverPage({
  required BuildContext context,
  required StationeryTheme theme,
  required bool isDark,
  required WeatherOutfitContext weatherContext,
  required bool useFahrenheit,
}) {
  SoundService().playClick();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.62),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, anim, secAnim) => Center(
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 460,
              maxHeight: MediaQuery.of(ctx).size.height * 0.88,
            ),
            child: _WhatToWearHoverPageContent(
              theme: theme,
              isDark: isDark,
              baseContext: weatherContext,
              useFahrenheit: useFahrenheit,
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (ctx, anim, secAnim, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _WhatToWearHoverPageContent extends StatefulWidget {
  final StationeryTheme theme;
  final bool isDark;
  final WeatherOutfitContext baseContext;
  final bool useFahrenheit;

  const _WhatToWearHoverPageContent({
    required this.theme,
    required this.isDark,
    required this.baseContext,
    required this.useFahrenheit,
  });

  @override
  State<_WhatToWearHoverPageContent> createState() => _WhatToWearHoverPageContentState();
}

class _WhatToWearHoverPageContentState extends State<_WhatToWearHoverPageContent> {
  OutfitPresetMode _preset = OutfitPresetMode.live;
  int _selectedKitIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = widget.isDark;
    final activeCtx = widget.baseContext.forPreset(_preset);
    final rec = OutfitRecommendation.compute(activeCtx);
    final tempDisplay = widget.useFahrenheit
        ? '${((activeCtx.tempC * 9 / 5) + 32).round()}°F'
        : '${activeCtx.tempC.round()}°C';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181D) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: theme.border, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.2),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(Icons.checkroom_rounded, size: 19, color: theme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What to Wear & Carry',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: theme.text,
                        ),
                      ),
                      Text(
                        '$tempDisplay • ${activeCtx.condition} • AQI ${activeCtx.aqi}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    SoundService().playClick();
                    Navigator.of(context).pop();
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF27272E) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, size: 18, color: theme.text),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.border.withValues(alpha: 0.7)),

          // 2. Scrollable Body
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Season / Weather Preset Switcher (defaults to Live Now)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        for (int idx = 0; idx < OutfitPresetMode.values.length; idx++) ...[
                          if (idx > 0) const SizedBox(width: 7),
                          Builder(
                            builder: (context) {
                              final mode = OutfitPresetMode.values[idx];
                              final selected = mode == _preset;
                              return BouncyTap(
                                onTap: () {
                                  SoundService().playTap();
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _preset = mode;
                                    _selectedKitIndex = 0;
                                  });
                                },
                                scaleFraction: 0.95,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? theme.primary
                                        : (isDark ? const Color(0xFF25252C) : theme.lavenderBubble),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: selected ? theme.primary : theme.border,
                                      width: 1.1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        mode.icon,
                                        size: 13.5,
                                        color: selected ? Colors.white : theme.primary,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        mode.label,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: selected ? Colors.white : theme.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Tooler Character Dressed for Active Weather & Gear
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF22222A) : theme.lavenderCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.border, width: 1.1),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: activeCtx.season.color.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(activeCtx.season.icon, size: 13, color: activeCtx.season.color),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${activeCtx.season.label} Gear',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: activeCtx.season.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                rec.hasOxygenCylinder
                                    ? 'O₂ + N95 Ready'
                                    : (rec.hasMask
                                        ? 'Mask On'
                                        : (rec.hasUmbrella ? 'Rain/UV Ready' : 'Equipped')),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: theme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        WearableToolerCharacter(
                          contextData: activeCtx,
                          recommendation: rec,
                          theme: theme,
                          isDark: isDark,
                          width: 210,
                          height: 195,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 5,
                          children: [
                            _miniTag(theme, isDark, rec.capType),
                            _miniTag(theme, isDark, rec.shirtType),
                            _miniTag(theme, isDark, rec.pantType),
                            _miniTag(theme, isDark, rec.footwearType),
                            if (rec.hasGloves) _miniTag(theme, isDark, rec.glovesType),
                            if (rec.hasRaincoat) _miniTag(theme, isDark, 'Raincoat'),
                            if (rec.hasUmbrella) _miniTag(theme, isDark, 'Umbrella'),
                            if (rec.hasMask) _miniTag(theme, isDark, 'N95 Mask'),
                            if (rec.hasOxygenCylinder) _miniTag(theme, isDark, 'O₂ Cylinder'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Clothing & Footwear Breakdown (Cap, Sweater, Shirt/T-Shirt, Pant, Boots/Shoes/Slippers, Gloves)
                  _sectionHeader(theme, 'What to Wear', Icons.accessibility_new_rounded),
                  const SizedBox(height: 8),
                  _buildTwoColRows(theme, isDark, [
                    _GearItemSpec(
                      title: 'Cap / Headwear',
                      value: rec.capType,
                      detail: rec.capDetail,
                      icon: Icons.face_retouching_natural_rounded,
                      accent: const Color(0xFFF59E0B),
                      active: rec.capStyle != CapStyle.none,
                    ),
                    _GearItemSpec(
                      title: 'Sweater / Outer',
                      value: rec.sweaterType,
                      detail: rec.sweaterDetail,
                      icon: Icons.layers_rounded,
                      accent: const Color(0xFF8B5CF6),
                      active: !rec.sweaterType.startsWith('No '),
                    ),
                    _GearItemSpec(
                      title: 'Shirt / T-Shirt',
                      value: rec.shirtType,
                      detail: rec.shirtDetail,
                      icon: Icons.checkroom_rounded,
                      accent: theme.primary,
                      active: true,
                    ),
                    _GearItemSpec(
                      title: 'Pant Type',
                      value: rec.pantType,
                      detail: rec.pantDetail,
                      icon: Icons.straighten_rounded,
                      accent: const Color(0xFF0EA5E9),
                      active: true,
                    ),
                    _GearItemSpec(
                      title: 'Boots / Shoes / Slippers',
                      value: rec.footwearType,
                      detail: rec.footwearDetail,
                      icon: Icons.hiking_rounded,
                      accent: const Color(0xFF10B981),
                      active: true,
                    ),
                    _GearItemSpec(
                      title: 'Gloves',
                      value: rec.glovesType,
                      detail: rec.glovesDetail,
                      icon: Icons.pan_tool_rounded,
                      accent: const Color(0xFF38BDF8),
                      active: rec.hasGloves,
                    ),
                  ]),
                  const SizedBox(height: 14),

                  // 5. Carry & Protection Gear (Raincoat, Umbrella, Mask, Oxygen Cylinder)
                  _sectionHeader(theme, 'What to Carry & Protection', Icons.backpack_rounded),
                  const SizedBox(height: 8),
                  _buildTwoColRows(theme, isDark, [
                    _GearItemSpec(
                      title: 'Raincoat',
                      value: rec.raincoatStatus,
                      detail: rec.raincoatDetail,
                      icon: Icons.cloudy_snowing,
                      accent: const Color(0xFF0284C7),
                      active: rec.hasRaincoat,
                    ),
                    _GearItemSpec(
                      title: 'Umbrella',
                      value: rec.umbrellaStatus,
                      detail: rec.umbrellaDetail,
                      icon: Icons.umbrella_rounded,
                      accent: const Color(0xFF6366F1),
                      active: rec.hasUmbrella,
                    ),
                    _GearItemSpec(
                      title: 'Mask',
                      value: rec.maskStatus,
                      detail: rec.maskDetail,
                      icon: Icons.masks_rounded,
                      accent: const Color(0xFFF97316),
                      active: rec.hasMask,
                    ),
                    _GearItemSpec(
                      title: 'Oxygen Cylinder',
                      value: rec.oxygenStatus,
                      detail: rec.oxygenDetail,
                      icon: Icons.medical_services_rounded,
                      accent: const Color(0xFFEF4444),
                      active: rec.hasOxygenCylinder,
                    ),
                  ]),
                  const SizedBox(height: 14),

                  // 6. Seasonal & Weather Tools (Snow, Summer, Winter, Autumn, Spring)
                  _sectionHeader(theme, 'Weather & Seasonal Tools', Icons.handyman_rounded),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: rec.allSeasonalKits.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, i) {
                        final kit = rec.allSeasonalKits[i];
                        final isSelected = i == _selectedKitIndex;
                        return InkWell(
                          onTap: () {
                            SoundService().playTap();
                            setState(() => _selectedKitIndex = i);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? kit.color.withValues(alpha: 0.18)
                                  : (isDark ? const Color(0xFF25252C) : const Color(0xFFF4F4F6)),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? kit.color : theme.border,
                                width: isSelected ? 1.4 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(kit.icon, size: 13.5, color: kit.color),
                                const SizedBox(width: 5),
                                Text(
                                  kit.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? kit.color : theme.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSeasonalToolsCard(
                    theme,
                    isDark,
                    rec.allSeasonalKits[_selectedKitIndex.clamp(0, rec.allSeasonalKits.length - 1)],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniTag(StationeryTheme theme, bool isDark, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D36) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.border.withValues(alpha: 0.7), width: 0.9),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: theme.text,
        ),
      ),
    );
  }

  Widget _sectionHeader(StationeryTheme theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: theme.text,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTwoColRows(
    StationeryTheme theme,
    bool isDark,
    List<_GearItemSpec> items,
  ) {
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      final first = items[i];
      final second = (i + 1 < items.length) ? items[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildGearTile(theme, isDark, first)),
              const SizedBox(width: 8),
              Expanded(
                child: second != null
                    ? _buildGearTile(theme, isDark, second)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < items.length) {
        rows.add(const SizedBox(height: 8));
      }
    }
    return Column(children: rows);
  }

  Widget _buildGearTile(StationeryTheme theme, bool isDark, _GearItemSpec item) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: item.active
            ? item.accent.withValues(alpha: isDark ? 0.14 : 0.08)
            : (isDark ? const Color(0xFF222228) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.active ? item.accent.withValues(alpha: 0.45) : theme.border.withValues(alpha: 0.7),
          width: item.active ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 14, color: item.active ? item.accent : theme.textSecondary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: theme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            item.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: item.active ? theme.text : theme.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              height: 1.25,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonalToolsCard(
    StationeryTheme theme,
    bool isDark,
    SeasonalKitSection kit,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222228) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kit.color.withValues(alpha: 0.35), width: 1.1),
      ),
      child: Column(
        children: kit.items.map((tool) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: tool.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(tool.icon, size: 16, color: tool.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tool.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: theme.text,
                        ),
                      ),
                      Text(
                        tool.detail,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GearItemSpec {
  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color accent;
  final bool active;

  const _GearItemSpec({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.accent,
    required this.active,
  });
}

/// ---------------------------------------------------------------------------
/// DYNAMIC TOOLER VECTOR CHARACTER DRESSED FOR WEATHER & TOOLS
/// Same Tooler character geometry & style (`#EAE2F8` skin, `#1D2436` hair/ink,
/// theme primary accent) with layered dynamic cap, sweater/shirt/t-shirt,
/// pants/shorts, boots/shoes/slippers, gloves, raincoat, umbrella, mask,
/// oxygen cylinder, and seasonal tools.
/// ---------------------------------------------------------------------------
class WearableToolerCharacter extends StatelessWidget {
  final WeatherOutfitContext contextData;
  final OutfitRecommendation recommendation;
  final StationeryTheme theme;
  final bool isDark;
  final double width;
  final double height;

  const WearableToolerCharacter({
    super.key,
    required this.contextData,
    required this.recommendation,
    required this.theme,
    required this.isDark,
    this.width = 200,
    this.height = 190,
  });

  String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  String _buildDynamicSvg() {
    final hexPrimary = _hex(theme.primary);
    final hexPrimaryDark = _hex(theme.primaryDark);
    const ink = '#1D2436';
    const skin = '#EAE2F8';
    const white = '#FFFFFF';
    final rec = recommendation;
    final ctx = contextData;

    final buf = StringBuffer();
    buf.write(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1134 1005" width="100%" height="100%" style="overflow: visible;">',
    );

    // 1. Subtle Seasonal / Weather Environment Accents behind character
    if (ctx.isSnow) {
      for (final pos in const [
        [220, 210, 12],
        [910, 200, 11],
        [260, 440, 10],
        [870, 470, 13],
        [180, 680, 10],
        [940, 690, 11],
      ]) {
        buf.write(
          '<circle cx="${pos[0]}" cy="${pos[1]}" r="${pos[2]}" fill="#BAE6FD" stroke="$ink" stroke-width="2"/>',
        );
      }
      // Snow shovel prop leaning beside character
      buf.write(
        '<path d="M 275 380 L 295 820" fill="none" stroke="$ink" stroke-width="14" stroke-linecap="round"/>'
        '<path d="M 248 805 L 342 805 L 348 905 Q 348 920 330 920 L 260 920 Q 242 920 242 905 Z" fill="$hexPrimary" stroke="$ink" stroke-width="4" stroke-linejoin="round"/>',
      );
    } else if (ctx.season == WeatherSeason.autumn && !ctx.isRain) {
      // Drifting autumn leaves
      for (final leaf in const [
        [210, 260, -25, '#F97316'],
        [880, 290, 22, '#DC2626'],
        [240, 560, 15, '#D97706'],
        [890, 620, -18, '#F97316'],
      ]) {
        buf.write(
          '<g transform="translate(${leaf[0]} ${leaf[1]}) rotate(${leaf[2]})">'
          '<path d="M 0 0 Q 22 -22, 56 0 Q 22 22, 0 0 Z" fill="${leaf[3]}" stroke="$ink" stroke-width="2.6"/>'
          '<path d="M 4 0 L 46 0" fill="none" stroke="$ink" stroke-width="1.8"/>'
          '</g>',
        );
      }
    } else if (ctx.season == WeatherSeason.summer || ctx.tempC >= 30) {
      // Warm sun badge in upper left + insulated bottle
      buf.write(
        '<circle cx="235" cy="215" r="44" fill="#FDE047" fill-opacity="0.7" stroke="$ink" stroke-width="3.2"/>'
        '<rect x="785" y="455" width="44" height="105" rx="14" fill="#38BDF8" stroke="$ink" stroke-width="3.2"/>'
        '<rect x="797" y="438" width="20" height="18" rx="4" fill="$ink"/>',
      );
    } else {
      // Spring fresh leaves / breeze
      buf.write(
        '<path d="M 190 320 C 235 280, 275 345, 320 305" fill="none" stroke="#5EEAD4" stroke-width="6" stroke-linecap="round"/>'
        '<path d="M 850 380 C 895 340, 935 405, 980 365" fill="none" stroke="#5EEAD4" stroke-width="6" stroke-linecap="round"/>',
      );
    }

    // Ground line
    buf.write(
      '<path d="M 120 920 L 1020 920" fill="none" stroke="$ink" stroke-width="4" stroke-linecap="round"/>',
    );

    // 2. Lower Body: Shorts vs Pants vs Thermal Snow Pants
    if (rec.pantStyle == PantStyle.shorts) {
      // Exposed lower legs in skin tone + white socks
      buf.write(
        '<rect x="498" y="620" width="52" height="255" rx="12" fill="$skin" stroke="$ink" stroke-width="3.2"/>'
        '<rect x="584" y="620" width="52" height="255" rx="12" fill="$skin" stroke="$ink" stroke-width="3.2"/>'
        '<path d="M 469 480 L 665 480 L 656 645 L 578 645 L 567 570 L 556 645 L 478 645 Z" fill="$hexPrimary" stroke="$ink" stroke-width="3.2" stroke-linejoin="round"/>',
      );
    } else if (rec.pantStyle == PantStyle.thermalSnowPants) {
      buf.write(
        '<path d="M 465 480 L 669 480 C 674 600, 658 750, 648 860 L 578 860 C 576 745, 574 635, 567 586 C 560 635, 558 745, 556 860 L 486 860 C 476 750, 460 600, 465 480 Z" fill="$hexPrimaryDark" stroke="$ink" stroke-width="3.4" stroke-linejoin="round"/>'
        '<path d="M 476 660 L 558 660 M 576 660 L 658 660" fill="none" stroke="$ink" stroke-width="2.6" stroke-linecap="round"/>',
      );
    } else {
      // Classic chinos / jeans / joggers
      buf.write(
        '<path d="M 469 480 L 665 480 C 667 600, 651 770, 641 880 L 581 880 C 579 760, 575 640, 567 586 C 559 640, 555 760, 553 880 L 493 880 C 483 770, 467 600, 469 480 Z" fill="$hexPrimary" stroke="$ink" stroke-width="3.2" stroke-linejoin="round"/>',
      );
    }

    // 3. Footwear: Slippers vs Sneakers vs Rain Boots vs Snow Boots
    if (rec.footwearStyle == FootwearStyle.slippers) {
      buf.write(
        '<path d="M 578 875 L 638 875 C 655 875, 672 888, 676 905 L 678 914 L 578 914 Z" fill="$skin" stroke="$ink" stroke-width="3.2"/>'
        '<path d="M 556 875 L 496 875 C 479 875, 462 888, 458 905 L 456 914 L 556 914 Z" fill="$skin" stroke="$ink" stroke-width="3.2"/>'
        '<path d="M 588 880 Q 618 874 646 896 L 632 908 Q 610 892 586 898 Z" fill="$hexPrimary" stroke="$ink" stroke-width="2.8"/>'
        '<path d="M 546 880 Q 516 874 488 896 L 502 908 Q 524 892 548 898 Z" fill="$hexPrimary" stroke="$ink" stroke-width="2.8"/>'
        '<path d="M 573 910 L 681 910 L 679 920 L 573 920 Z" fill="$ink"/>'
        '<path d="M 561 910 L 453 910 L 455 920 L 561 920 Z" fill="$ink"/>',
      );
    } else if (rec.footwearStyle == FootwearStyle.rainBoots || rec.footwearStyle == FootwearStyle.snowBoots) {
      final bootColor = rec.footwearStyle == FootwearStyle.snowBoots ? '#475569' : hexPrimary;
      final cuffColor = rec.footwearStyle == FootwearStyle.snowBoots ? '#F8FAFC' : hexPrimaryDark;
      buf.write(
        '<path d="M 577 780 L 645 780 L 647 872 C 664 872, 675 886, 679 904 L 680 912 L 576 912 Z" fill="$bootColor" stroke="$ink" stroke-width="3.2" stroke-linejoin="round"/>'
        '<path d="M 557 780 L 489 780 L 487 872 C 470 872, 459 886, 455 904 L 454 912 L 558 912 Z" fill="$bootColor" stroke="$ink" stroke-width="3.2" stroke-linejoin="round"/>'
        '<rect x="575" y="766" width="72" height="22" rx="8" fill="$cuffColor" stroke="$ink" stroke-width="2.8"/>'
        '<rect x="487" y="766" width="72" height="22" rx="8" fill="$cuffColor" stroke="$ink" stroke-width="2.8"/>'
        '<path d="M 572 908 L 684 908 L 682 920 L 572 920 Z" fill="$ink"/>'
        '<path d="M 562 908 L 450 908 L 452 920 L 562 920 Z" fill="$ink"/>',
      );
    } else {
      // Classic sneakers
      buf.write(
        '<path d="M 577 872 L 641 872 C 657 872, 673 884, 677 900 L 679 910 C 679 918, 673 920, 665 920 L 577 920 Z" fill="$white" stroke="$ink" stroke-width="3.2" stroke-linejoin="round"/>'
        '<path d="M 573 912 L 681 912 L 679 920 L 573 920 Z" fill="$ink"/>'
        '<path d="M 557 872 L 493 872 C 477 872, 461 884, 457 900 L 455 910 C 455 918, 461 920, 469 920 L 557 920 Z" fill="$white" stroke="$ink" stroke-width="3.2" stroke-linejoin="round"/>'
        '<path d="M 561 912 L 453 912 L 455 920 L 561 920 Z" fill="$ink"/>',
      );
    }

    // 4. Neck
    buf.write(
      '<rect x="547" y="226" width="40" height="44" fill="$skin" stroke="$ink" stroke-width="3.2"/>',
    );

    // 5. Oxygen Cylinder behind left arm when active
    if (rec.hasOxygenCylinder) {
      buf.write(
        '<rect x="345" y="372" width="68" height="190" rx="16" fill="$white" stroke="$ink" stroke-width="3.2"/>'
        '<rect x="369" y="348" width="20" height="26" fill="$ink"/>'
        '<rect x="345" y="478" width="68" height="28" fill="$hexPrimary" stroke="$ink" stroke-width="2.6"/>'
        '<circle cx="379" cy="402" r="10" fill="$white" stroke="$ink" stroke-width="2.6"/>'
        '<path d="M 379 402 L 384 396" fill="none" stroke="$ink" stroke-width="2" stroke-linecap="round"/>'
        '<text x="379" y="528" font-family="monospace" font-size="26" font-weight="900" fill="$ink" text-anchor="middle">O2</text>',
      );
    }

    // 6. Upper Body & Sleeves
    final bool isShortSleeve = rec.topStyle == TopStyle.tShirt;
    final bool isRaincoat = rec.topStyle == TopStyle.raincoat;
    final bool isSweaterOrPuffer = rec.topStyle == TopStyle.sweater || rec.topStyle == TopStyle.pufferJacket;

    final String torsoFill = isRaincoat
        ? '#0284C7'
        : (rec.topStyle == TopStyle.pufferJacket
            ? hexPrimaryDark
            : (rec.topStyle == TopStyle.sweater ? hexPrimary : ink));

    // Torso shape (longer when raincoat)
    if (isRaincoat) {
      buf.write(
        '<path d="M 534 256 C 488 256, 456 270, 452 302 L 455 578 Q 457 596, 476 596 L 658 596 Q 677 596, 679 578 L 682 302 C 678 270, 646 256, 600 256 Q 567 266, 534 256 Z" fill="$torsoFill" stroke="$ink" stroke-width="3.4" stroke-linejoin="round"/>'
        '<path d="M 567 265 L 567 594" fill="none" stroke="$ink" stroke-width="3" stroke-linecap="round"/>'
        '<rect x="485" y="438" width="46" height="44" rx="8" fill="#0369A1" stroke="$ink" stroke-width="2.4"/>'
        '<rect x="603" y="438" width="46" height="44" rx="8" fill="#0369A1" stroke="$ink" stroke-width="2.4"/>',
      );
    } else {
      buf.write(
        '<path d="M 537 255 C 493 255, 461 267, 457 298 L 467 482 Q 469 502, 487 502 L 647 502 Q 665 502, 667 482 L 677 298 C 673 267, 641 255, 597 255 Q 567 264, 537 255 Z" fill="$torsoFill" stroke="$ink" stroke-width="3.2" stroke-linejoin="round"/>',
      );
      if (rec.topStyle == TopStyle.pufferJacket) {
        buf.write(
          '<path d="M 465 335 L 669 335 M 467 395 L 667 395 M 469 452 L 665 452 M 567 265 L 567 500" fill="none" stroke="$ink" stroke-width="2.6" stroke-linecap="round"/>',
        );
      } else if (rec.topStyle == TopStyle.sweater) {
        buf.write(
          '<rect x="530" y="246" width="74" height="22" rx="10" fill="$torsoFill" stroke="$ink" stroke-width="3"/>'
          '<rect x="468" y="476" width="198" height="24" rx="6" fill="$hexPrimaryDark" stroke="$ink" stroke-width="2.6"/>',
        );
      } else if (rec.topStyle == TopStyle.casualShirt) {
        buf.write(
          '<path d="M 537 255 L 557 290 L 567 266 L 577 290 L 597 255" fill="$white" stroke="$ink" stroke-width="2.8" stroke-linejoin="round"/>'
          '<path d="M 567 268 L 567 492" fill="none" stroke="$white" stroke-width="2.2" stroke-dasharray="6 14"/>',
        );
      }
    }

    // Left Arm (holds oxygen cylinder if active, otherwise relaxed)
    if (rec.hasOxygenCylinder) {
      buf.write(
        '<path d="M 469 294 L 433 398 L 417 486" fill="none" stroke="$torsoFill" stroke-width="60" stroke-linecap="round" stroke-linejoin="round"/>'
        '<path d="M 469 294 L 433 398 L 417 486" fill="none" stroke="$ink" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" opacity="0.25"/>',
      );
    } else if (isShortSleeve) {
      buf.write(
        '<path d="M 467 300 L 456 385" fill="none" stroke="$torsoFill" stroke-width="62" stroke-linecap="round"/>'
        '<path d="M 456 385 L 449 514" fill="none" stroke="$skin" stroke-width="34" stroke-linecap="round"/>'
        '<path d="M 456 385 L 449 514" fill="none" stroke="$ink" stroke-width="3.2" stroke-linecap="round" opacity="0.18"/>',
      );
    } else {
      buf.write(
        '<path d="M 467 300 L 455 410 L 449 514" fill="none" stroke="$torsoFill" stroke-width="62" stroke-linecap="round" stroke-linejoin="round"/>',
      );
    }

    // Right Arm (raised if holding umbrella, otherwise relaxed)
    final rightHandX = rec.hasUmbrella ? 752.0 : 685.0;
    final rightHandY = rec.hasUmbrella ? 378.0 : 528.0;
    if (rec.hasUmbrella) {
      buf.write(
        '<path d="M 667 300 L 724 395 L 752 378" fill="none" stroke="$torsoFill" stroke-width="60" stroke-linecap="round" stroke-linejoin="round"/>',
      );
    } else if (isShortSleeve) {
      buf.write(
        '<path d="M 667 300 L 678 385" fill="none" stroke="$torsoFill" stroke-width="62" stroke-linecap="round"/>'
        '<path d="M 678 385 L 685 514" fill="none" stroke="$skin" stroke-width="34" stroke-linecap="round"/>',
      );
    } else {
      buf.write(
        '<path d="M 667 300 L 679 410 L 685 514" fill="none" stroke="$torsoFill" stroke-width="62" stroke-linecap="round" stroke-linejoin="round"/>',
      );
    }

    // Knit cuffs on sweater
    if (isSweaterOrPuffer && !rec.hasUmbrella && !rec.hasOxygenCylinder) {
      buf.write(
        '<ellipse cx="449" cy="500" rx="22" ry="10" fill="$hexPrimaryDark" stroke="$ink" stroke-width="2.6"/>'
        '<ellipse cx="685" cy="500" rx="22" ry="10" fill="$hexPrimaryDark" stroke="$ink" stroke-width="2.6"/>',
      );
    }

    // Hands or Gloves
    final handFill = rec.hasGloves ? hexPrimaryDark : skin;
    final leftHandX = rec.hasOxygenCylinder ? 414.5 : 448.2;
    final leftHandY = rec.hasOxygenCylinder ? 499.8 : 528.0;
    final handRx = rec.hasGloves ? 20 : 15;
    final handRy = rec.hasGloves ? 24 : 19;
    buf.write(
      '<ellipse cx="$leftHandX" cy="$leftHandY" rx="$handRx" ry="$handRy" fill="$handFill" stroke="$ink" stroke-width="3.2"/>'
      '<ellipse cx="$rightHandX" cy="$rightHandY" rx="$handRx" ry="$handRy" fill="$handFill" stroke="$ink" stroke-width="3.2"/>',
    );

    // 7. Umbrella (held in right hand overhead)
    if (rec.hasUmbrella) {
      buf.write(
        '<path d="M 752 385 L 752 108" fill="none" stroke="$ink" stroke-width="7" stroke-linecap="round"/>'
        '<path d="M 752 385 C 752 415, 725 415, 725 392" fill="none" stroke="$ink" stroke-width="6" stroke-linecap="round"/>'
        '<path d="M 592 162 Q 752 50 912 162 Q 860 144 806 162 Q 752 144 698 162 Q 645 144 592 162 Z" fill="$hexPrimary" stroke="$ink" stroke-width="3.4" stroke-linejoin="round"/>'
        '<path d="M 752 106 L 752 94" fill="none" stroke="$ink" stroke-width="7" stroke-linecap="round"/>',
      );
    }

    // 8. Head, Hair, Face, Sunglasses, Mask
    buf.write(
      '<g>'
      '<ellipse cx="527" cy="210" rx="9" ry="13" fill="$skin" stroke="$ink" stroke-width="3.2"/>'
      '<ellipse cx="607" cy="210" rx="9" ry="13" fill="$skin" stroke="$ink" stroke-width="3.2"/>'
      '<path d="M 521 196 C 513 150, 521 124, 553 120 C 579 116, 613 128, 615 160 C 617 178, 615 190, 613 204 L 603 198 C 603 172, 587 160, 563 162 C 543 162, 529 176, 527 196 Z" fill="$ink"/>'
      '<path d="M 529 186 C 527 160, 545 150, 569 150 C 593 150, 607 164, 607 188 C 607 214, 605 236, 597 250 C 589 262, 579 268, 569 268 C 557 268, 543 264, 537 252 C 529 240, 527 214, 529 186 Z" fill="$skin" stroke="$ink" stroke-width="3.2" stroke-linejoin="round"/>',
    );

    if (rec.hasSunglasses && !rec.hasMask) {
      buf.write(
        '<rect x="536" y="196" width="26" height="17" rx="5" fill="$ink"/>'
        '<rect x="572" y="196" width="26" height="17" rx="5" fill="$ink"/>'
        '<line x1="562" y1="202" x2="572" y2="202" stroke="$ink" stroke-width="3.2"/>',
      );
    } else {
      buf.write(
        '<ellipse cx="551" cy="206" rx="3.6" ry="5.2" fill="$ink"/>'
        '<ellipse cx="583" cy="206" rx="3.6" ry="5.2" fill="$ink"/>',
      );
    }

    buf.write(
      '<path d="M 541 184 Q 551 179, 559 182" fill="none" stroke="$ink" stroke-width="4" stroke-linecap="round"/>'
      '<path d="M 575 182 Q 583 179, 593 184" fill="none" stroke="$ink" stroke-width="4" stroke-linecap="round"/>'
      '<path d="M 569 214 Q 564 226, 571 230" fill="none" stroke="$ink" stroke-width="2.8" stroke-linecap="round"/>',
    );

    if (rec.hasMask) {
      buf.write(
        '<path d="M 531 230 Q 525 214, 527 200" fill="none" stroke="$ink" stroke-width="2.6" stroke-linecap="round"/>'
        '<path d="M 603 230 Q 609 214, 607 200" fill="none" stroke="$ink" stroke-width="2.6" stroke-linecap="round"/>'
        '<path d="M 533 220 Q 569 210, 603 220 C 607 236, 605 256, 597 262 Q 569 280, 539 262 C 531 256, 529 236, 533 220 Z" fill="$white" stroke="$ink" stroke-width="3.2" stroke-linejoin="round"/>'
        '<path d="M 545 236 L 589 236 M 547 248 L 587 248" fill="none" stroke="$ink" stroke-width="2" stroke-linecap="round"/>',
      );
    } else {
      buf.write(
        '<path d="M 556 242 Q 569 254, 582 242" fill="none" stroke="$ink" stroke-width="3.2" stroke-linecap="round"/>',
      );
    }

    // 9. Headwear (Cap / Wool Beanie / Rain Hood)
    switch (rec.capStyle) {
      case CapStyle.baseballCap:
        buf.write(
          '<path d="M 518 166 C 520 122, 548 106, 572 106 C 598 106, 616 126, 616 164 Z" fill="$hexPrimary" stroke="$ink" stroke-width="3.2" stroke-linejoin="round"/>'
          '<path d="M 516 164 Q 574 150, 650 168 Q 620 176, 516 166 Z" fill="$hexPrimaryDark" stroke="$ink" stroke-width="3.2" stroke-linejoin="round"/>'
          '<circle cx="570" cy="105" r="5" fill="$hexPrimaryDark" stroke="$ink" stroke-width="2.5"/>',
        );
        break;
      case CapStyle.woolBeanie:
        buf.write(
          '<circle cx="569" cy="96" r="14" fill="$hexPrimaryDark" stroke="$ink" stroke-width="3"/>'
          '<path d="M 520 162 C 520 118, 545 104, 569 104 C 593 104, 616 118, 616 162 Z" fill="$hexPrimary" stroke="$ink" stroke-width="3.2" stroke-linejoin="round"/>'
          '<rect x="516" y="150" width="104" height="24" rx="10" fill="$hexPrimaryDark" stroke="$ink" stroke-width="3.2"/>'
          '<path d="M 542 152 L 542 172 M 568 152 L 568 172 M 594 152 L 594 172" fill="none" stroke="$ink" stroke-width="2.2"/>',
        );
        break;
      case CapStyle.rainHood:
        buf.write(
          '<path d="M 512 184 C 508 118, 542 98, 570 98 C 600 98, 626 122, 622 184 L 610 170 C 604 140, 588 128, 568 128 C 546 128, 528 142, 522 172 Z" fill="#0284C7" stroke="$ink" stroke-width="3.2" stroke-linejoin="round"/>',
        );
        break;
      case CapStyle.sunBucketHat:
        buf.write(
          '<path d="M 522 158 C 524 120, 546 106, 569 106 C 592 106, 612 120, 614 158 Z" fill="$hexPrimary" stroke="$ink" stroke-width="3.2" stroke-linejoin="round"/>'
          '<path d="M 498 164 Q 569 148, 640 164 Q 569 178, 498 164 Z" fill="$hexPrimaryDark" stroke="$ink" stroke-width="3.2" stroke-linejoin="round"/>',
        );
        break;
      case CapStyle.none:
        break;
    }

    buf.write('</g>');

    // 10. Oxygen tube connecting cylinder to mask
    if (rec.hasOxygenCylinder) {
      buf.write(
        '<path d="M 379 346 C 379 292, 447 262, 527 232" fill="none" stroke="$ink" stroke-width="5" stroke-linecap="round"/>',
      );
    }

    buf.write('</svg>');
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final svg = _buildDynamicSvg();
    return SizedBox(
      width: width,
      height: height,
      child: SvgPicture.string(
        svg,
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}
