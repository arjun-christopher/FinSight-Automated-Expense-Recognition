class ExpenseCategories {
  static const String food = 'Food & Dining';
  static const String groceries = 'Groceries';
  static const String transportation = 'Transportation';
  static const String shopping = 'Shopping';
  static const String entertainment = 'Entertainment';
  static const String utilities = 'Utilities';
  static const String healthcare = 'Healthcare';
  static const String education = 'Education';
  static const String travel = 'Travel';
  static const String fitness = 'Fitness';
  static const String personal = 'Personal Care';
  static const String home = 'Home & Garden';
  static const String business = 'Business';
  static const String insurance = 'Insurance';
  static const String gifts = 'Gifts & Donations';
  static const String subscriptions = 'Subscriptions';
  static const String other = 'Other';

  static const List<String> all = [
    food,
    groceries,
    transportation,
    shopping,
    entertainment,
    utilities,
    healthcare,
    education,
    travel,
    fitness,
    personal,
    home,
    business,
    insurance,
    gifts,
    subscriptions,
    other,
  ];

  static String getEmoji(String category) {
    switch (category) {
      case food:
        return '🍽️';
      case groceries:
        return '🛒';
      case transportation:
        return '🚗';
      case shopping:
        return '🛍️';
      case entertainment:
        return '🎬';
      case utilities:
        return '💡';
      case healthcare:
        return '🏥';
      case education:
        return '📚';
      case travel:
        return '✈️';
      case fitness:
        return '💪';
      case personal:
        return '💅';
      case home:
        return '🏠';
      case business:
        return '💼';
      case insurance:
        return '🛡️';
      case gifts:
        return '🎁';
      case subscriptions:
        return '📱';
      default:
        return '📊';
    }
  }
}

class PaymentMethods {
  static const String cash = 'Cash';
  static const String creditCard = 'Credit Card';
  static const String debitCard = 'Debit Card';
  static const String bankTransfer = 'Bank Transfer';
  static const String digitalWallet = 'Digital Wallet';
  static const String upi = 'UPI';
  static const String other = 'Other';

  static const List<String> all = [
    cash,
    creditCard,
    debitCard,
    bankTransfer,
    digitalWallet,
    upi,
    other,
  ];
}
