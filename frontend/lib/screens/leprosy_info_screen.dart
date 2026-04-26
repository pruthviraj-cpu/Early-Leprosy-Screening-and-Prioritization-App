import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Design tokens (matched with home.dart) ──────────────────────────────────
const _bg            = Color(0xFFF6F8FC);
const _surface       = Color(0xFFFFFFFF);
const _teal          = Color(0xFF1A73E8);
const _tealLight     = Color(0xFFE8F0FE);
const _textPrimary   = Color(0xFF1F1F1F);
const _textSecondary = Color(0xFF5F6368);
const _border        = Color(0xFFE8EAED);
const _green         = Color(0xFF188038);

class LeprosyInfoScreen extends StatefulWidget {
  const LeprosyInfoScreen({super.key});

  @override
  State<LeprosyInfoScreen> createState() => _LeprosyInfoScreenState();
}

class _LeprosyInfoScreenState extends State<LeprosyInfoScreen> {
  String _selectedLang = 'English';

  final Map<String, Map<String, dynamic>> _content = {
    'English': {
      'appBar': 'National Health Guidelines',
      'title': 'Leprosy Awareness & Guidance',
      'subtitle': 'Official Information Portal',
      'sections': [
        {
          'title': 'What is Leprosy?',
          'icon': Icons.info_outline_rounded,
          'content': 'Leprosy (Hansen\'s disease) is a chronic infectious disease caused by Mycobacterium leprae. It primarily affects the skin, peripheral nerves, and mucosal surfaces.',
        },
        {
          'title': 'Causes & Transmission',
          'icon': Icons.people_outline_rounded,
          'content': 'Spread via respiratory droplets during prolonged close contact with untreated cases. It is NOT hereditary and NOT highly contagious.',
        },
        {
          'title': 'Early Symptoms',
          'icon': Icons.visibility_outlined,
          'content': '• Pale or reddish skin patches with loss of sensation\n• Numbness in hands or feet\n• Weakness in muscles\n• Thickened nerves',
        },
        {
          'title': 'Treatment (MDT)',
          'icon': Icons.medication_outlined,
          'content': 'Leprosy is 100% curable. Multi-Drug Therapy (MDT) is provided FREE of cost at all government health facilities worldwide.',
        },
        {
          'title': 'When to Seek Help',
          'icon': Icons.medical_services_outlined,
          'content': 'Consult a doctor if you find any skin patch that does not feel touch, heat, or pain. Early detection prevents disability.',
        },
      ],
      'schemeTitle': 'Government Schemes & Support',
      'schemes': [
        {
          'name': 'National Leprosy Eradication Programme (NLEP)',
          'desc': 'Provides free diagnosis and Multi-Drug Therapy (MDT) at all government health centers (PHC/CHC).',
          'url': 'https://dghs.mohfw.gov.in/nlep.php',
          'btn': 'Visit NLEP Portal',
        },
        {
          'name': 'Reconstructive Surgery (RCS)',
          'desc': 'Financial assistance and free surgery provided for correction of leprosy-related deformities.',
          'url': 'https://nhm.gov.in/index4.php?lang=1&level=0&lid=348&linkid=281',
          'btn': 'Surgery Details',
        },
        {
          'name': 'Ministry of Health (NLEP Section)',
          'desc': 'Official portal of the Ministry of Health and Family Welfare for Leprosy eradication.',
          'url': 'https://www.mohfw.gov.in/',
          'btn': 'Visit MoHFW',
        },
      ],
      'mythTitle': 'Myth vs Fact',
      'myths': [
        {'m': 'Leprosy is a curse.', 'f': 'It is a bacterial infection.'},
        {'m': 'It spreads by touch.', 'f': 'It requires long-term close contact.'},
      ]
    },
    'हिंदी': {
      'appBar': 'राष्ट्रीय स्वास्थ्य दिशा-निर्देश',
      'title': 'कुष्ठ रोग जागरूकता एवं मार्गदर्शन',
      'subtitle': 'आधिकारिक सूचना पोर्टल',
      'sections': [
        {
          'title': 'कुष्ठ रोग क्या है?',
          'icon': Icons.info_outline_rounded,
          'content': 'कुष्ठ रोग (हैनसेन रोग) माइकोबैक्टीरियम लेप्राई के कारण होने वाला एक पुराना संक्रामक रोग है। यह मुख्य रूप से त्वचा और तंत्रिकाओं को प्रभावित करता है।',
        },
        {
          'title': 'कारण और प्रसार',
          'icon': Icons.people_outline_rounded,
          'content': 'यह अनुपचारित मामलों के साथ लंबे समय तक निकट संपर्क के दौरान श्वसन बूंदों के माध्यम से फैलता है। यह वंशानुगत नहीं है।',
        },
        {
          'title': 'शुरुआती लक्षण',
          'icon': Icons.visibility_outlined,
          'content': '• त्वचा पर हल्के या लाल रंग के धब्बे जिनमें संवेदनशीलता की कमी हो\n• हाथों या पैरों में सुन्नपन\n• मांसपेशियों में कमजोरी\n• नसों में सूजन',
        },
        {
          'title': 'उपचार (MDT)',
          'icon': Icons.medication_outlined,
          'content': 'कुष्ठ रोग 100% साध्य है। मल्टी-ड्रग थेरेपी (MDT) सभी सरकारी स्वास्थ्य केंद्रों पर मुफ्त उपलब्ध कराई जाती है।',
        },
        {
          'title': 'चिकित्सीय सहायता कब लें',
          'icon': Icons.medical_services_outlined,
          'content': 'यदि आपको त्वचा पर कोई ऐसा धब्बा दिखे जिसमें स्पर्श, गर्मी या दर्द महसूस न हो, तो तुरंत डॉक्टर से संपर्क करें।',
        },
      ],
      'schemeTitle': 'सरकारी योजनाएं और सहायता',
      'schemes': [
        {
          'name': 'राष्ट्रीय कुष्ठ उन्मूलन कार्यक्रम (NLEP)',
          'desc': 'सभी सरकारी स्वास्थ्य केंद्रों (PHC/CHC) पर मुफ्त निदान और मल्टी-ड्रग थेरेपी (MDT) प्रदान करता है।',
          'url': 'https://nlep.nic.in/',
          'btn': 'NLEP पोर्टल पर जाएं',
        },
        {
          'name': 'पुनर्निर्माण सर्जरी (RCS)',
          'desc': 'कुष्ठ रोग से संबंधित विकृतियों के सुधार के लिए वित्तीय सहायता और मुफ्त सर्जरी प्रदान की जाती है।',
          'url': 'https://nlep.nic.in/ReconstructiveSurgery.html',
          'btn': 'सर्जरी का विवरण',
        },
        {
          'name': 'स्वास्थ्य मंत्रालय (NLEP अनुभाग)',
          'desc': 'कुष्ठ उन्मूलन के लिए स्वास्थ्य और परिवार कल्याण मंत्रालय का आधिकारिक पोर्टल।',
          'url': 'https://main.mohfw.gov.in/Major-Programmes/National-Leprosy-Eradication-Programme-NLEP',
          'btn': 'MoHFW पोर्टल पर जाएं',
        },
      ],
      'mythTitle': 'भ्रम बनाम तथ्य',
      'myths': [
        {'m': 'कुष्ठ रोग एक अभिशाप है।', 'f': 'यह एक जीवाणु संक्रमण है।'},
        {'m': 'यह छूने से फैलता है।', 'f': 'इसके लिए लंबे समय तक निकट संपर्क की आवश्यकता होती है।'},
      ]
    }
  };

  @override
  Widget build(BuildContext context) {
    final current = _content[_selectedLang]!;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          current['appBar'],
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary),
        ),
        backgroundColor: _surface,
        elevation: 0,
        centerTitle: true,
        actions: [
          _buildLanguageToggle(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),
          _buildOfficialHeader(current['title'], current['subtitle']),
          const SizedBox(height: 20),
          ...current['sections'].map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _InfoCard(title: s['title'], icon: s['icon'], content: s['content']),
          )).toList(),
          const SizedBox(height: 12),
          Text(
            current['schemeTitle'],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary),
          ),
          const SizedBox(height: 12),
          ...current['schemes'].map((s) => _SchemeCard(
            name: s['name'], 
            description: s['desc'],
            url: s['url'],
            buttonText: s['btn'],
          )).toList(),
          const SizedBox(height: 20),
          Text(
            current['mythTitle'],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary),
          ),
          const SizedBox(height: 12),
          ...current['myths'].map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MythFactCard(myth: m['m'], fact: m['f'], lang: _selectedLang),
          )).toList(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLanguageToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: _tealLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _content.keys.map((lang) {
          final isSelected = _selectedLang == lang;
          return GestureDetector(
            onTap: () => setState(() => _selectedLang = lang),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? _teal : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                lang,
                style: TextStyle(
                  color: isSelected ? Colors.white : _teal,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOfficialHeader(String title, String subtitle) {
    return Column(
      children: [
        const Icon(Icons.account_balance_rounded, color: _teal, size: 40),
        const SizedBox(height: 12),
        Text(
          title.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 2,
          width: 60,
          color: _teal,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: _textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String content;

  const _InfoCard({required this.title, required this.icon, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: _teal, size: 22),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.topLeft,
        children: [
          Text(
            content,
            style: const TextStyle(fontSize: 14, color: _textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _MythFactCard extends StatelessWidget {
  final String myth;
  final String fact;
  final String lang;

  const _MythFactCard({required this.myth, required this.fact, required this.lang});

  @override
  Widget build(BuildContext context) {
    final mythLabel = lang == 'English' ? 'MYTH' : 'भ्रम';
    final factLabel = lang == 'English' ? 'FACT' : 'तथ्य';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Tag(label: mythLabel, color: const Color(0xFFD93025), bgColor: const Color(0xFFFDE7E7)),
              const SizedBox(width: 8),
              Expanded(child: Text(myth, style: const TextStyle(fontSize: 13, color: _textSecondary, fontStyle: FontStyle.italic))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Tag(label: factLabel, color: _green, bgColor: const Color(0xFFE6F4EA)),
              const SizedBox(width: 8),
              Expanded(child: Text(fact, style: const TextStyle(fontSize: 14, color: _textPrimary, fontWeight: FontWeight.w500))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  const _Tag({required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}

class _SchemeCard extends StatelessWidget {
  final String name;
  final String description;
  final String url;
  final String buttonText;

  const _SchemeCard({
    required this.name, 
    required this.description, 
    required this.url,
    required this.buttonText,
  });

  Future<void> _launchUrl() async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _tealLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _teal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: _teal, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _teal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: _textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _launchUrl,
              icon: const Icon(Icons.open_in_new_rounded, size: 14),
              label: Text(buttonText),
              style: TextButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
