import 'package:flutter/material.dart';

// ─── Color Constants (same as main.dart) ─────────────────────────────────────
const kBlue   = Color(0xFF0052FF);
const kOrange = Color(0xFFFF6B00);
const kBg     = Color(0xFFF2F3F5);
const kWhite  = Colors.white;
const kGreen  = Color(0xFF00C48C);

// ─── Profile Page ─────────────────────────────────────────────────────────────

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // ── Derived spending data from order history ─────────────────────────────
  static const _totalSpent    = 57.50;
  static const _totalOrders   = 4;
  static const _avgPerOrder   = 14.38;

  static const _monthlySpend = [
    _MonthSpend('Sep', 0),
    _MonthSpend('Oct', 12.0),
    _MonthSpend('Nov', 37.0),
    _MonthSpend('Dec', 10.0),
  ];

  static const _favourites = [
    _FavRestaurant(
      name: 'Bake & Brew',
      category: 'Bakery · Café',
      orders: 3,
      totalSpent: 14.00,
      photo:
          'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=300',
      badgeColor: Color(0xFFE8EEFF),
      badgeTextColor: kBlue,
    ),
    _FavRestaurant(
      name: 'Mak Cik Siti',
      category: 'Malaysian · Local',
      orders: 2,
      totalSpent: 10.00,
      photo:
          'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=300',
      badgeColor: Color(0xFFFFF0E0),
      badgeTextColor: kOrange,
    ),
    _FavRestaurant(
      name: 'Ramen House',
      category: 'Japanese · Noodles',
      orders: 1,
      totalSpent: 14.00,
      photo:
          'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=300',
      badgeColor: Color(0xFFE6FFF5),
      badgeTextColor: kGreen,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: kBg,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
            top: topPad + 16, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header title ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Profile',
                    style: TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  // Settings icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.settings_outlined,
                        size: 18, color: Color(0xFF1A1A2E)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Profile Card ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ProfileCard(),
            ),

            const SizedBox(height: 16),

            // ── Stats Row ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _StatsRow(),
            ),

            const SizedBox(height: 20),

            // ── Spending Chart ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SpendingCard(monthlySpend: _monthlySpend),
            ),

            const SizedBox(height: 20),

            // ── Favourite Restaurants ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Favourite Places',
                    style: TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Based on your orders',
                    style: TextStyle(
                        color: Colors.grey[400], fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            ..._favourites.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _FavouriteCard(
                      restaurant: e.value, rank: e.key + 1),
                )),
          ],
        ),
      ),
    );
  }
}

// ─── Profile Card ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kBlue, Color(0xFF003FCC)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kBlue.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: kWhite.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'N',
                        style: TextStyle(
                          color: kWhite,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  // Online dot
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: kGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: kBlue, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Name + matric
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Najwa Binti Amir',
                      style: TextStyle(
                        color: kWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kWhite.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '2023423456',
                            style: TextStyle(
                              color: kWhite,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.school_rounded,
                            color: kWhite, size: 12,),
                        const SizedBox(width: 4),
                        Text(
                          'UiTM Shah Alam',
                          style: TextStyle(
                            color: kWhite.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Edit Profile Button
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              height: 42,
              decoration: BoxDecoration(
                color: kWhite.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: kWhite.withOpacity(0.3), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.edit_rounded, color: kWhite, size: 15),
                  SizedBox(width: 8),
                  Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: kWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          label: 'Total Spent',
          value: 'RM 57.50',
          icon: Icons.account_balance_wallet_rounded,
          color: kBlue,
          bgColor: const Color(0xFFE8EEFF),
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Orders',
          value: '4',
          icon: Icons.shopping_bag_rounded,
          color: kOrange,
          bgColor: const Color(0xFFFFF0E0),
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Avg / Order',
          value: 'RM 14.38',
          icon: Icons.trending_up_rounded,
          color: kGreen,
          bgColor: const Color(0xFFE6FFF5),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Spending Chart Card ──────────────────────────────────────────────────────

class _SpendingCard extends StatelessWidget {
  final List<_MonthSpend> monthlySpend;

  const _SpendingCard({required this.monthlySpend});

  @override
  Widget build(BuildContext context) {
    final maxVal = monthlySpend
        .map((e) => e.amount)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EEFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                        Icons.bar_chart_rounded,
                        size: 15,
                        color: kBlue),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'My Spending',
                    style: TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                'Last 4 months',
                style:
                    TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Bar chart
          SizedBox(
            height: 112,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: monthlySpend.map((item) {
                final ratio =
                    maxVal > 0 ? item.amount / maxVal : 0.0;
                final isHighest = item.amount == maxVal;
                return _BarColumn(
                  month: item.month,
                  amount: item.amount,
                  ratio: ratio,
                  isHighest: isHighest,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  final String month;
  final double amount;
  final double ratio;
  final bool isHighest;

  const _BarColumn({
    required this.month,
    required this.amount,
    required this.ratio,
    required this.isHighest,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Amount label above bar
        if (amount > 0)
          Text(
            'RM${amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: isHighest ? kBlue : Colors.grey[400],
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        const SizedBox(height: 4),
        // Bar
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          width: 36,
          height: ratio * 64,
          decoration: BoxDecoration(
            color: isHighest ? kBlue : const Color(0xFFE8EEFF),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 6),
        // Month label
        Text(
          month,
          style: TextStyle(
            color: isHighest
                ? const Color(0xFF1A1A2E)
                : Colors.grey[400],
            fontSize: 11,
            fontWeight:
                isHighest ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─── Favourite Restaurant Card ────────────────────────────────────────────────

class _FavouriteCard extends StatelessWidget {
  final _FavRestaurant restaurant;
  final int rank;

  const _FavouriteCard(
      {required this.restaurant, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank == 1
                  ? const Color(0xFFFFF3E0)
                  : rank == 2
                      ? const Color(0xFFF0F0F0)
                      : const Color(0xFFFFF0E8),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: rank == 1
                      ? const Color(0xFFFFAA00)
                      : rank == 2
                          ? Colors.grey[500]
                          : const Color(0xFFCD7F32),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Restaurant photo
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: kBg,
            ),
            clipBehavior: Clip.hardEdge,
            child: Image.network(
              restaurant.photo,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFE8EEFF),
                child: const Icon(Icons.storefront_rounded,
                    color: kBlue),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  style: const TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  restaurant.category,
                  style: TextStyle(
                      color: Colors.grey[400], fontSize: 11),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: restaurant.badgeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${restaurant.orders} orders',
                        style: TextStyle(
                          color: restaurant.badgeTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Total spent
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'RM ${restaurant.totalSpent.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'total spent',
                style:
                    TextStyle(color: Colors.grey[400], fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Data Classes ─────────────────────────────────────────────────────────────

class _MonthSpend {
  final String month;
  final double amount;
  const _MonthSpend(this.month, this.amount);
}

class _FavRestaurant {
  final String name;
  final String category;
  final int orders;
  final double totalSpent;
  final String photo;
  final Color badgeColor;
  final Color badgeTextColor;

  const _FavRestaurant({
    required this.name,
    required this.category,
    required this.orders,
    required this.totalSpent,
    required this.photo,
    required this.badgeColor,
    required this.badgeTextColor,
  });
}