import 'dart:math';

/// 🛡️ SERVIÇO DE DETECÇÃO DE FRAUDES - CAMADA 3
/// 
/// Sistema de IA baseado em regras para análise de risco de transações
/// Score de 0-100 determina se aprova, revisa ou bloqueia
enum RiskLevel {
  low,    // 0-30: Aprovar automaticamente
  medium, // 31-70: Revisão manual
  high,   // 71-100: Bloquear e investigar
}

class FraudRiskScore {
  final int score;
  final RiskLevel level;
  final List<String> factors;
  final bool shouldBlock;
  final bool requiresReview;

  FraudRiskScore({
    required this.score,
    required this.level,
    required this.factors,
    required this.shouldBlock,
    required this.requiresReview,
  });

  @override
  String toString() {
    return 'FraudRiskScore(score: $score, level: $level, block: $shouldBlock, review: $requiresReview)';
  }
}

class FraudDetectionService {
  static final FraudDetectionService _instance = FraudDetectionService._internal();
  factory FraudDetectionService() => _instance;
  FraudDetectionService._internal();

  // Configurações de threshold
  static const int LOW_RISK_THRESHOLD = 30;
  static const int MEDIUM_RISK_THRESHOLD = 70;
  static const int HIGH_RISK_THRESHOLD = 71;

  // Limites padrão
  static const double MAX_ORDER_AMOUNT = 500.0; // R$ 500,00
  static const int MAX_ORDERS_PER_HOUR = 5;
  static const int MAX_DISTANCE_KM = 50;

  /// Analisa transação e retorna score de risco
  Future<FraudRiskScore> analyzeTransaction({
    required String userId,
    required double amount,
    required String paymentMethod,
    required Map<String, dynamic> userLocation,
    required String deviceId,
    String? deliveryAddress,
    Map<String, dynamic>? additionalData,
  }) async {
    int totalScore = 0;
    List<String> riskFactors = [];

    // 1. Análise do Comportamento do Usuário
    final userBehaviorScore = await _analyzeUserBehavior(userId, amount);
    totalScore += userBehaviorScore.score;
    riskFactors.addAll(userBehaviorScore.factors);

    // 2. Análise do Dispositivo e Rede
    final deviceScore = await _analyzeDevice(deviceId, userId);
    totalScore += deviceScore.score;
    riskFactors.addAll(deviceScore.factors);

    // 3. Análise do Padrão de Pagamento
    final paymentScore = _analyzePaymentPattern(paymentMethod, amount, userId);
    totalScore += paymentScore.score;
    riskFactors.addAll(paymentScore.factors);

    // 4. Análise de Geolocalização
    final geoScore = await _analyzeGeolocation(
      userId,
      userLocation,
      deliveryAddress,
    );
    totalScore += geoScore.score;
    riskFactors.addAll(geoScore.factors);

    // 5. Análise de Valor da Transação
    final amountScore = _analyzeTransactionAmount(amount, userId);
    totalScore += amountScore.score;
    riskFactors.addAll(amountScore.factors);

    // Normalizar score (máximo 100)
    final normalizedScore = min(totalScore, 100);

    // Determinar nível de risco
    final RiskLevel level;
    if (normalizedScore <= LOW_RISK_THRESHOLD) {
      level = RiskLevel.low;
    } else if (normalizedScore <= MEDIUM_RISK_THRESHOLD) {
      level = RiskLevel.medium;
    } else {
      level = RiskLevel.high;
    }

    return FraudRiskScore(
      score: normalizedScore,
      level: level,
      factors: riskFactors,
      shouldBlock: level == RiskLevel.high,
      requiresReview: level == RiskLevel.medium,
    );
  }

  /// 1. Análise do Comportamento do Usuário
  Future<({int score, List<String> factors})> _analyzeUserBehavior(
    String userId,
    double amount,
  ) async {
    int score = 0;
    List<String> factors = [];

    // Simulação: Em produção, consultar banco de dados
    // final userHistory = await _getUserHistory(userId);
    
    // Fator: Primeira compra (+20 pontos)
    final isFirstPurchase = await _isFirstPurchase(userId);
    if (isFirstPurchase) {
      score += 20;
      factors.add('Primeira compra do usuário');
    }

    // Fator: Valor muito acima da média histórica (+30 pontos)
    final avgOrderValue = await _getAverageOrderValue(userId);
    if (avgOrderValue > 0 && amount > (avgOrderValue * 2)) {
      score += 30;
      factors.add('Valor ${((amount / avgOrderValue) * 100).toStringAsFixed(0)}% acima da média');
    }

    // Fator: Múltiplos pedidos em pouco tempo (+25 pontos)
    final recentOrders = await _getRecentOrdersCount(userId, hours: 1);
    if (recentOrders >= MAX_ORDERS_PER_HOUR) {
      score += 25;
      factors.add('$recentOrders pedidos na última hora (limite: $MAX_ORDERS_PER_HOUR)');
    }

    // Fator: Conta recém-criada (< 24h) (+15 pontos)
    final accountAge = await _getAccountAgeInHours(userId);
    if (accountAge < 24) {
      score += 15;
      factors.add('Conta criada há ${accountAge.toStringAsFixed(1)} horas');
    }

    // Fator: Usuário nunca completou um pedido (+20 pontos)
    final hasCompletedOrder = await _hasCompletedOrder(userId);
    if (!hasCompletedOrder) {
      score += 20;
      factors.add('Nenhum pedido completo anteriormente');
    }

    return (score: score, factors: factors);
  }

  /// 2. Análise do Dispositivo e Rede
  Future<({int score, List<String> factors})> _analyzeDevice(
    String deviceId,
    String userId,
  ) async {
    int score = 0;
    List<String> factors = [];

    // Fator: Device fingerprint novo (+15 pontos)
    final isKnownDevice = await _isKnownDevice(deviceId, userId);
    if (!isKnownDevice) {
      score += 15;
      factors.add('Dispositivo não reconhecido');
    }

    // Fator: Múltiplas contas no mesmo dispositivo (+50 pontos)
    final accountsOnDevice = await _getAccountsOnDevice(deviceId);
    if (accountsOnDevice > 2) {
      score += 50;
      factors.add('$accountsOnDevice contas neste dispositivo');
    }

    // Fator: IP de proxy/VPN detectado (+35 pontos)
    // final isProxy = await _detectProxy(ipAddress);
    // if (isProxy) {
    //   score += 35;
    //   factors.add('Proxy/VPN detectado');
    // }

    // Fator: Emulador detectado (+60 pontos)
    // final isEmulator = await _detectEmulator(deviceId);
    // if (isEmulator) {
    //   score += 60;
    //   factors.add('Emulador detectado');
    // }

    // Fator: Dispositivo com root/jailbreak (+40 pontos)
    final isRooted = await _isRootedDevice(deviceId);
    if (isRooted) {
      score += 40;
      factors.add('Dispositivo com root/jailbreak');
    }

    // Fator: Horário incomum de acesso (3-5 AM) (+15 pontos)
    final hour = DateTime.now().hour;
    if (hour >= 3 && hour <= 5) {
      score += 15;
      factors.add('Acesso em horário incomum (${hour}h)');
    }

    return (score: score, factors: factors);
  }

  /// 3. Análise do Padrão de Pagamento
  ({int score, List<String> factors}) _analyzePaymentPattern(
    String paymentMethod,
    double amount,
    String userId,
  ) {
    int score = 0;
    List<String> factors = [];

    // Fator: Cartão recusado anteriormente (+25 pontos)
    // final hasDeclinedCard = await _hasDeclinedCard(userId);
    // if (hasDeclinedCard) {
    //   score += 25;
    //   factors.add('Cartão recusado anteriormente');
    // }

    // Fator: Múltiplos cartões cadastrados (+20 pontos)
    // final cardCount = await _getCardCount(userId);
    // if (cardCount > 3) {
    //   score += 20;
    //   factors.add('$cardCount cartões cadastrados');
    // }

    // Fator: Tentativa de valores fracionados suspeitos (+30 pontos)
    if (_isSuspiciousAmount(amount)) {
      score += 30;
      factors.add('Valor fracionado suspeito (R$ ${amount.toStringAsFixed(2)})');
    }

    // Fator: Método de pagamento de alto risco (+15 pontos)
    if (paymentMethod == 'pix' && amount > 200) {
      score += 15;
      factors.add('PIX de valor elevado');
    }

    // Fator: Cartão pré-pago (+20 pontos)
    // final isPrepaid = await _isPrepaidCard(cardToken);
    // if (isPrepaid) {
    //   score += 20;
    //   factors.add('Cartão pré-pago');
    // }

    return (score: score, factors: factors);
  }

  /// 4. Análise de Geolocalização
  Future<({int score, List<String> factors})> _analyzeGeolocation(
    String userId,
    Map<String, dynamic> userLocation,
    String? deliveryAddress,
  ) async {
    int score = 0;
    List<String> factors = [];

    // Fator: Distância entre localização atual e endereço de entrega
    if (deliveryAddress != null) {
      final distance = await _calculateDistance(userLocation, deliveryAddress);
      
      if (distance > MAX_DISTANCE_KM) {
        score += 25;
        factors.add('Distância de ${distance.toStringAsFixed(1)}km (limite: ${MAX_DISTANCE_KM}km)');
      }

      // Fator: Endereço em área de alto risco (+20 pontos)
      final isHighRiskArea = await _isHighRiskArea(deliveryAddress);
      if (isHighRiskArea) {
        score += 20;
        factors.add('Endereço em área de alto risco');
      }
    }

    // Fator: Múltiplos endereços em curto período (+30 pontos)
    final addressCount = await _getAddressCount(userId, days: 7);
    if (addressCount > 3) {
      score += 30;
      factors.add('$addressCount endereços diferentes em 7 dias');
    }

    // Fator: Mudança brusca de localização (+40 pontos)
    final lastLocation = await _getLastKnownLocation(userId);
    if (lastLocation != null) {
      final distanceFromLast = _calculateDistanceBetween(
        lastLocation,
        userLocation,
      );
      
      // Se moveu mais de 100km em menos de 1 hora
      if (distanceFromLast > 100) {
        final timeSinceLast = await _getTimeSinceLastLocation(userId);
        if (timeSinceLast < 60) { // minutos
          score += 40;
          factors.add('Movimento suspeito: ${distanceFromLast.toStringAsFixed(0)}km em ${timeSinceLast}min');
        }
      }
    }

    return (score: score, factors: factors);
  }

  /// 5. Análise de Valor da Transação
  ({int score, List<String> factors}) _analyzeTransactionAmount(
    double amount,
    String userId,
  ) {
    int score = 0;
    List<String> factors = [];

    // Fator: Valor acima do limite máximo (+35 pontos)
    if (amount > MAX_ORDER_AMOUNT) {
      score += 35;
      factors.add('Valor acima do limite (R$ ${amount.toStringAsFixed(2)} > R$ ${MAX_ORDER_AMOUNT.toStringAsFixed(2)})');
    }

    // Fator: Valor redondo suspeito (+10 pontos)
    if (amount % 100 == 0 && amount >= 300) {
      score += 10;
      factors.add('Valor redondo suspeito (R$ ${amount.toStringAsFixed(2)})');
    }

    // Fator: Primeiro pedido de valor alto (+25 pontos)
    final isFirstPurchase = _isFirstPurchase(userId);
    if (isFirstPurchase && amount > 150) {
      score += 25;
      factors.add('Primeiro pedido de valor elevado');
    }

    return (score: score, factors: factors);
  }

  /// Bloqueia transação suspeita
  Future<void> blockTransaction(String transactionId, FraudRiskScore risk) async {
    // Registrar bloqueio no banco de dados
    debugPrint('🚫 Transação $transactionId BLOQUEADA');
    debugPrint('   Score: ${risk.score} (${risk.level})');
    debugPrint('   Fatores: ${risk.factors.join(", ")}');
    
    // Enviar notificação para equipe de segurança
    await _notifySecurityTeam(transactionId, risk);
    
    // Notificar usuário (mensagem genérica para não revelar regras)
    await _notifyUser(transactionId);
  }

  /// Envia transação para revisão manual
  Future<void> flagForReview(String transactionId, FraudRiskScore risk) async {
    debugPrint('⚠️ Transação $transactionId ENVIADA PARA REVISÃO');
    debugPrint('   Score: ${risk.score} (${risk.level})');
    debugPrint('   Fatores: ${risk.factors.join(", ")}');
    
    // Adicionar à fila de revisão
    await _addToReviewQueue(transactionId, risk);
  }

  /// Registra transação aprovada para aprendizado
  Future<void> recordApprovedTransaction(String transactionId, FraudRiskScore risk) async {
    debugPrint('✅ Transação $transactionId APROVADA');
    debugPrint('   Score: ${risk.score} (${risk.level})');
    
    // Registrar para melhorar modelo de IA
    await _recordForML(transactionId, risk);
  }

  // =========================================================================
  // MÉTODOS AUXILIARES (Simulações - Em produção, consultar banco de dados)
  // =========================================================================

  Future<bool> _isFirstPurchase(String userId) async {
    // TODO: Implementar consulta ao banco
    return false; // Simular que não é primeira compra
  }

  Future<double> _getAverageOrderValue(String userId) async {
    // TODO: Implementar consulta ao banco
    return 85.0; // Média de R$ 85,00
  }

  Future<int> _getRecentOrdersCount(String userId, {required int hours}) async {
    // TODO: Implementar consulta ao banco
    return 1; // 1 pedido nas últimas horas
  }

  Future<double> _getAccountAgeInHours(String userId) async {
    // TODO: Implementar consulta ao banco
    return 720; // 30 dias
  }

  Future<bool> _hasCompletedOrder(String userId) async {
    // TODO: Implementar consulta ao banco
    return true;
  }

  Future<bool> _isKnownDevice(String deviceId, String userId) async {
    // TODO: Implementar consulta ao banco
    return true;
  }

  Future<int> _getAccountsOnDevice(String deviceId) async {
    // TODO: Implementar consulta ao banco
    return 1;
  }

  Future<bool> _isRootedDevice(String deviceId) async {
    // TODO: Implementar verificação
    return false;
  }

  bool _isSuspiciousAmount(double amount) {
    // Detectar padrões como R$ 99,99, R$ 199,99 (testes de cartão)
    final decimalPart = amount - amount.floor();
    return decimalPart > 0.95 && decimalPart < 0.99;
  }

  Future<double> _calculateDistance(
    Map<String, dynamic> userLocation,
    String address,
  ) async {
    // TODO: Implementar cálculo usando Google Maps API
    return 5.0; // 5km
  }

  Future<bool> _isHighRiskArea(String address) async {
    // TODO: Implementar verificação de áreas de risco
    return false;
  }

  Future<int> _getAddressCount(String userId, {required int days}) async {
    // TODO: Implementar consulta ao banco
    return 1;
  }

  Future<Map<String, dynamic>?> _getLastKnownLocation(String userId) async {
    // TODO: Implementar consulta ao banco
    return null;
  }

  double _calculateDistanceBetween(
    Map<String, dynamic> loc1,
    Map<String, dynamic> loc2,
  ) {
    // Fórmula de Haversine para distância entre coordenadas
    // TODO: Implementar cálculo real
    return 0.0;
  }

  Future<int> _getTimeSinceLastLocation(String userId) async {
    // TODO: Implementar consulta ao banco
    return 120; // minutos
  }

  Future<void> _notifySecurityTeam(String transactionId, FraudRiskScore risk) async {
    // TODO: Implementar envio de email/slack para equipe
    debugPrint('📧 Equipe de segurança notificada');
  }

  Future<void> _notifyUser(String transactionId) async {
    // TODO: Implementar notificação push para usuário
    debugPrint('📱 Usuário notificado (mensagem genérica)');
  }

  Future<void> _addToReviewQueue(String transactionId, FraudRiskScore risk) async {
    // TODO: Implementar fila de revisão
    debugPrint('📋 Adicionado à fila de revisão');
  }

  Future<void> _recordForML(String transactionId, FraudRiskScore risk) async {
    // TODO: Implementar registro para machine learning
    debugPrint('🤖 Registrado para aprendizado de IA');
  }
}

// Exemplo de uso:
/*
final fraudDetector = FraudDetectionService();

final risk = await fraudDetector.analyzeTransaction(
  userId: 'user_123',
  amount: 150.00,
  paymentMethod: 'credit_card',
  userLocation: {'lat': -23.5505, 'lng': -46.6333},
  deviceId: 'device_fingerprint_xyz',
  deliveryAddress: 'Rua Augusta, 100 - São Paulo',
);

if (risk.shouldBlock) {
  await fraudDetector.blockTransaction('order_456', risk);
} else if (risk.requiresReview) {
  await fraudDetector.flagForReview('order_456', risk);
} else {
  await fraudDetector.recordApprovedTransaction('order_456', risk);
}
*/
