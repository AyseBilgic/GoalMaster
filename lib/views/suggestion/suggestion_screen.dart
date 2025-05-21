// lib/views/suggestion/suggestion_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/goal_provider.dart'; // GoalProvider importu

class SuggestionScreen extends StatefulWidget {
  final int goalId; // Hangi hedef için öneri alınacağını belirtir
  const SuggestionScreen({required this.goalId, super.key});

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  // Future'ı state içinde tutmak, gereksiz API çağrılarını önler
   @override
  void initState() {
    super.initState();
    // Düzeltme: build tamamlandıktan sonra fetch işlemini başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // mounted kontrolü callback içinde önemli
      if (mounted) {
        // Provider'ı alıp direkt fetch işlemini tetikle
        Provider.of<GoalProvider>(context, listen: false)
            .fetchGoalSuggestions(widget.goalId);
      }
    });
     // _fetchSuggestionsFuture = _fetchSuggestionsOnLoad(); // Bu kaldırıldı
  }

  // build metodu tamamlandıktan sonra önerileri çekmek için güvenli metot
  

  // Kullanıcı tarafından tetiklenecek yenileme metodu
  Future<void> _refreshSuggestions() async {
    if (mounted) {
      final goalProvider = Provider.of<GoalProvider>(context, listen: false);
      // Zaten yüklenmiyorsa tekrar çek
      if (!goalProvider.isSuggestionLoading(widget.goalId)) {
         // setState kullanmaya gerek yok, Provider state'i güncelleyecek
         await goalProvider.fetchGoalSuggestions(widget.goalId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar( title: const Text('AI Önerileri'), ),
      // FutureBuilder yerine doğrudan Consumer kullanmak daha basit olabilir
      // Çünkü ilk yükleme ve sonraki güncellemeler Provider state'i üzerinden yönetiliyor.
      body: Consumer<GoalProvider>(
        builder: (context, goalProvider, child) {
            // State'leri provider'dan al
            final isLoading = goalProvider.isSuggestionLoading(widget.goalId);
            final errorMessage = goalProvider.getSuggestionError(widget.goalId);
            final suggestions = goalProvider.getSuggestionsForGoal(widget.goalId);

            // Yükleniyor durumu (liste boşken)
            if (isLoading && suggestions.isEmpty) {
               return _buildLoadingIndicator();
            }
            // Hata durumu
            if (errorMessage != null) {
              return _buildErrorWidget(context, errorMessage);
            }
            // Öneri yok durumu
            if (suggestions.isEmpty && !isLoading) { // Yüklenmiyorsa ve boşsa
              return _buildEmptyStateWidget(context);
            }
            // Öneriler listesi
            return _buildSuggestionList(context, suggestions);
        },
      ),
      // Yenileme FAB'ı (Consumer içinde olması state'i doğru okumasını sağlar)
      floatingActionButton: Consumer<GoalProvider>(
         builder: (context, goalProvider, _) {
            final isRefreshing = goalProvider.isSuggestionLoading(widget.goalId);
            return FloatingActionButton(
               onPressed: isRefreshing ? null : _refreshSuggestions,
               tooltip: 'Önerileri Yenile', mini: true,
               child: isRefreshing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.refresh, size: 24),
            );
         }
      ),
    );
  }

  // --- Yardımcı Build Metodları ---

  Widget _buildLoadingIndicator() {
     return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    final theme = Theme.of(context);
    return Center(
      child: Padding( padding: const EdgeInsets.all(20.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.cloud_off_outlined, color: theme.colorScheme.error, size: 60),
          const SizedBox(height: 16),
          Text('Hata Oluştu!', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
          const SizedBox(height: 24),
          ElevatedButton.icon(onPressed: _refreshSuggestions, icon: const Icon(Icons.refresh, size: 18), label: const Text("Tekrar Dene"))
        ]), ), );
  }

   Widget _buildEmptyStateWidget(BuildContext context) {
     final theme = Theme.of(context);
      return Center( child: Padding( padding: const EdgeInsets.all(30.0), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.lightbulb_outline_rounded, size: 70, color: theme.colorScheme.primary.withOpacity(0.6)), // Düzeltme: withOpacity
            const SizedBox(height: 20),
            Text('Öneri Bulunamadı', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text( 'Bu hedef için henüz AI önerisi üretilemedi veya mevcut değil.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700), textAlign: TextAlign.center, ),
            const SizedBox(height: 25),
            ElevatedButton.icon(onPressed: _refreshSuggestions, icon: const Icon(Icons.refresh, size: 18), label: const Text("Tekrar Dene"), )
            ], ), ) );
   }

  Widget _buildSuggestionList(BuildContext context, List<String> suggestionsData) {
     final theme = Theme.of(context);
    return RefreshIndicator( // Listeye de pull-to-refresh ekle
      onRefresh: _refreshSuggestions,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        itemCount: suggestionsData.length,
        itemBuilder: (context, index) {
          final suggestion = suggestionsData[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
               // Düzeltme: Deprecated surfaceVariant yerine alternatif (veya kendi temanızdan)
               color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5), // M3 alternatifi
               // color: theme.colorScheme.primaryContainer.withOpacity(0.3), // Başka bir alternatif
               borderRadius: BorderRadius.circular(12),
               border: Border.all(color: theme.dividerColor.withOpacity(0.5), width: 0.5) // withOpacity düzeltildi
            ),
            child: Row( crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding( padding: const EdgeInsets.only(top: 3.0, right: 12.0),
                   child: Icon(Icons.task_alt_outlined, color: theme.colorScheme.primary, size: 20), ),
                Expanded(child: Text(suggestion, style: theme.textTheme.bodyLarge?.copyWith(height: 1.4))),
              ], ), ); }, ),
    );
  }
}