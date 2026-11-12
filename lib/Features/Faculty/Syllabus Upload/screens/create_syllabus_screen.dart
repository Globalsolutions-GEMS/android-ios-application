import 'package:erp_app/Core/theme/app_theme.dart';
import 'package:erp_app/Core/widgets/app_form_fields.dart';
import 'package:erp_app/Features/Faculty/Syllabus Upload/Bloc/create_syllabus_bloc.dart';
import 'package:erp_app/Features/Faculty/Syllabus Upload/Bloc/create_syllabus_event.dart';
import 'package:erp_app/Features/Faculty/Syllabus Upload/Bloc/create_syllabus_state.dart';
import 'package:erp_app/Features/Faculty/Syllabus Upload/model/create_syllabus_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateSyllabusScreen extends StatefulWidget {
  const CreateSyllabusScreen({super.key});

  @override
  State<CreateSyllabusScreen> createState() => _CreateSyllabusScreenState();
}

class _CreateSyllabusScreenState extends State<CreateSyllabusScreen> {
  int _selectedTab = 0;

  late final CreateSyllabusBloc _bloc;

  static const Color _primary = Color(0xFF6D4AFF);
  static const Color _dark = Color(0xFF172033);
  static const Color _grey = Color(0xFF64748B);
  static const Color _border = Color(0xFFD5DAE5);
  static const Color _fieldBorder = Color(0xFFB8C0D0);

  // Syllabus Unit
  List<FacultySubject> _facultySubjects = [];
  List<SyllabusUnit> _loadedUnits = [];

  int? _selectedSubjectId;
  int? _editingUnitId;

  bool _isLoadingSubjects = true;
  bool _isLoadingUnits = false;
  bool _isSavingUnit = false;
  bool _unitActive = true;

  // Syllabus Topic API state
  List<SyllabusTopic> _topics = <SyllabusTopic>[];
  List<SyllabusUnit> _topicUnits = <SyllabusUnit>[];
  int? _selectedTopicUnitId;
  int? _editingTopicId;
  bool _isLoadingTopics = false;
  bool _isSavingTopic = false;

  int? _selectedTopicSubjectId;
  String? _selectedTopicUnitName;
  bool _topicActive = true;

  final TextEditingController _unitNumberController = TextEditingController();
  final TextEditingController _unitNameController = TextEditingController();

  final TextEditingController _topicNumberController = TextEditingController();
  final TextEditingController _topicNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _lectureCountController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _bloc = CreateSyllabusBloc()..add(const LoadFacultySubjects());
  }

  @override
  void dispose() {
    _bloc.close();

    _unitNumberController.dispose();
    _unitNameController.dispose();
    _topicNumberController.dispose();
    _topicNameController.dispose();
    _descriptionController.dispose();
    _lectureCountController.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // THEME HELPERS
  // ------------------------------------------------------------

  // Same field look as the global dropdown (bordered, white)
  InputDecoration _inputDecoration({
    required BuildContext context,
    String? hint,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 14,
        color: Color(0xFF6B7280),
        fontFamily: 'Nunito',
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _fieldBorder, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _fieldBorder, width: 1.2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(AppTheme.showThemedSnackBar(context, message));
  }

  // ------------------------------------------------------------
  // BLOC STATE HANDLING
  // ------------------------------------------------------------

  void _handleSyllabusState(BuildContext context, CreateSyllabusState state) {
    if (!mounted) return;

    if (state is CreateSyllabusLoading) {
      setState(() {
        _isLoadingSubjects = true;
      });
    } else if (state is FacultySubjectsLoaded) {
      setState(() {
        _facultySubjects = state.subjects;
        _isLoadingSubjects = false;
        _isLoadingUnits = false;
        _isSavingUnit = false;
      });
    } else if (state is SyllabusUnitsLoaded) {
      setState(() {
        _facultySubjects = state.subjects;
        _selectedSubjectId = state.selectedSubjectId;
        _loadedUnits = state.units;

        _isLoadingSubjects = false;
        _isLoadingUnits = false;
        _isSavingUnit = false;
      });
    } else if (state is CreateSyllabusSaving) {
      setState(() {
        _isSavingUnit = true;
      });
    } else if (state is CreateSyllabusSuccess) {
      setState(() {
        _facultySubjects = state.subjects;
        _selectedSubjectId = state.selectedSubjectId;
        _loadedUnits = state.units;

        _isLoadingSubjects = false;
        _isLoadingUnits = false;
        _isSavingUnit = false;

        _editingUnitId = null;
        _unitNumberController.clear();
        _unitNameController.clear();
        _unitActive = true;
      });

      _showMessage(state.message);
    } else if (state is TopicUnitsLoading) {
      setState(() {
        _topicUnits = [];
        _selectedTopicUnitId = null;
        _topics = [];
        _isLoadingUnits = true;
      });
    } else if (state is TopicUnitsLoaded) {
      setState(() {
        _topicUnits = state.units;
        _isLoadingUnits = false;
      });
    } else if (state is TopicUnitsFailure) {
      setState(() {
        _isLoadingUnits = false;
      });
      _showMessage(state.message);
    } else if (state is SyllabusTopicsLoading) {
      setState(() {
        _isLoadingTopics = true;
        _isSavingTopic = false;
        _topics = [];
      });
    } else if (state is SyllabusTopicsLoaded) {
      setState(() {
        _topics = state.topics;
        _selectedTopicUnitId = state.unitId == 0 ? null : state.unitId;
        _isLoadingTopics = false;
        _isSavingTopic = false;
      });
    } else if (state is SyllabusTopicSaving) {
      setState(() {
        _isSavingTopic = true;
      });
    } else if (state is SyllabusTopicSuccess) {
      setState(() {
        _topics = state.topics;
        _selectedTopicUnitId = state.unitId;
        _isLoadingTopics = false;
        _isSavingTopic = false;
        _editingTopicId = null;
        _topicNumberController.clear();
        _topicNameController.clear();
        _descriptionController.clear();
        _lectureCountController.clear();
        _topicActive = true;
      });
      _showMessage(state.message);
    } else if (state is CreateSyllabusTopicFailure) {
      setState(() {
        _isLoadingTopics = false;
        _isSavingTopic = false;
      });
      _showMessage(state.message);
    } else if (state is CreateSyllabusFailure) {
      setState(() {
        _isLoadingSubjects = false;
        _isLoadingUnits = false;
        _isSavingUnit = false;
      });
      _showMessage(state.message);
    }
  }

  // ------------------------------------------------------------
  // SUBJECT SELECTION
  // ------------------------------------------------------------

  void _onSubjectChanged(int? subjectId) {
    if (subjectId == null || _isSavingUnit) return;

    setState(() {
      _selectedSubjectId = subjectId;
      _loadedUnits = [];
      _isLoadingUnits = true;

      _editingUnitId = null;
      _unitNumberController.clear();
      _unitNameController.clear();
      _unitActive = true;
    });

    _bloc.add(LoadSyllabusUnits(subjectId: subjectId));
  }

  void _onTopicSubjectChanged(int? subjectId) {
    if (subjectId == null || _isSavingTopic) return;
    setState(() {
      _selectedTopicSubjectId = subjectId;
      _selectedTopicUnitName = null;
      _selectedTopicUnitId = null;
      _topicUnits = [];
      _topics = [];
    });
    _bloc.add(LoadTopicUnits(subjectId: subjectId));
  }

  void _onTopicUnitChanged(int? unitId) {
    if (unitId == null || _isSavingTopic) return;
    SyllabusUnit? unit;
    for (final item in _topicUnits) {
      if (item.id == unitId) {
        unit = item;
        break;
      }
    }
    setState(() {
      _selectedTopicUnitId = unitId;
      _selectedTopicUnitName = unit?.unitName;
      _editingTopicId = null;
      _topics = [];
    });
    _bloc.add(LoadSyllabusTopics(unitId: unitId));
  }

  String? _validateTopicForm() {
    if (_selectedTopicSubjectId == null) return 'Please select a syllabus.';
    if (_selectedTopicUnitId == null) return 'Please select a unit.';
    final number = _topicNumberController.text.trim();
    if (number.isEmpty) return 'Please enter the topic number.';
    if (!RegExp(r'^\d+$').hasMatch(number))
      return 'Topic number must be a whole number.';
    if (_topicNameController.text.trim().isEmpty)
      return 'Please enter the topic name.';
    final lectures = int.tryParse(_lectureCountController.text.trim());
    if (lectures == null || lectures < 0)
      return 'Please enter a valid number of lectures.';
    return null;
  }

  void _saveSyllabusTopic() {
    if (_isSavingTopic || _isLoadingTopics) return;
    final validation = _validateTopicForm();
    if (validation != null) {
      _showMessage(validation);
      return;
    }
    final unitId = _selectedTopicUnitId!;
    final args = {
      'unitId': unitId,
      'topicNumber': _topicNumberController.text.trim(),
      'topicName': _topicNameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'noOfLectures': int.parse(_lectureCountController.text.trim()),
      'active': _topicActive,
    };
    if (_editingTopicId != null) {
      _bloc.add(
        UpdateSyllabusTopic(
          topicId: _editingTopicId!,
          unitId: unitId,
          topicNumber: args['topicNumber'] as String,
          topicName: args['topicName'] as String,
          description: args['description'] as String,
          noOfLectures: args['noOfLectures'] as int,
          active: args['active'] as bool,
        ),
      );
    } else {
      _bloc.add(
        CreateSyllabusTopic(
          unitId: unitId,
          topicNumber: args['topicNumber'] as String,
          topicName: args['topicName'] as String,
          description: args['description'] as String,
          noOfLectures: args['noOfLectures'] as int,
          active: args['active'] as bool,
        ),
      );
    }
  }

  void _editTopic(SyllabusTopic topic) {
    setState(() {
      _editingTopicId = topic.id;
      _topicNumberController.text = topic.topicNumber;
      _topicNameController.text = topic.topicName;
      _descriptionController.text = topic.description;
      _lectureCountController.text = topic.noOfLectures.toString();
      _topicActive = topic.active;
    });
  }

  // ------------------------------------------------------------
  // CREATE / UPDATE VALIDATION
  // ------------------------------------------------------------

  String? _validateUnitForm() {
    if (_selectedSubjectId == null) {
      return 'Please select a syllabus.';
    }

    final unitNumber = _unitNumberController.text.trim();
    final unitName = _unitNameController.text.trim();

    if (unitNumber.isEmpty) {
      return 'Please enter the unit number.';
    }

    if (!RegExp(r'^\d+$').hasMatch(unitNumber)) {
      return 'Unit number must be a whole number.';
    }

    if (unitName.isEmpty) {
      return 'Please enter the unit name.';
    }

    if (!RegExp(r'^[A-Za-z0-9 .-]+$').hasMatch(unitName)) {
      return 'Unit name can contain letters, numbers, spaces, dots and hyphens.';
    }

    return null;
  }

  void _saveSyllabusUnit() {
    if (_isSavingUnit || _isLoadingUnits) return;

    final validationMessage = _validateUnitForm();

    if (validationMessage != null) {
      _showMessage(validationMessage);
      return;
    }

    final subjectId = _selectedSubjectId!;
    final unitNo = _unitNumberController.text.trim();
    final unitName = _unitNameController.text.trim();

    if (_editingUnitId != null) {
      _bloc.add(
        UpdateSyllabusUnit(
          unitId: _editingUnitId!,
          subjectId: subjectId,
          unitNo: unitNo,
          unitName: unitName,
          active: _unitActive,
        ),
      );
    } else {
      _bloc.add(
        CreateSyllabusUnit(
          subjectId: subjectId,
          unitNo: unitNo,
          unitName: unitName,
          active: _unitActive,
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // EDIT UNIT
  // ------------------------------------------------------------

  void _editUnit(SyllabusUnit unit) {
    if (_isSavingUnit) return;

    setState(() {
      _editingUnitId = unit.id;
      _unitNumberController.text = unit.unitNo;
      _unitNameController.text = unit.unitName;
      _unitActive = unit.active;
    });
  }

  // ------------------------------------------------------------
  // CANCEL / RESET
  // ------------------------------------------------------------

  void _cancelUnitForm() {
    if (_isSavingUnit) return;

    setState(() {
      _unitNumberController.clear();
      _unitNameController.clear();

      _editingUnitId = null;
      _selectedSubjectId = null;
      _loadedUnits = [];

      _unitActive = true;
      _isLoadingUnits = false;
    });

    _bloc.add(const ResetCreateSyllabus());
  }

  void _cancelTopicForm() {
    setState(() {
      _topicNumberController.clear();
      _topicNameController.clear();
      _descriptionController.clear();
      _lectureCountController.clear();

      _selectedTopicSubjectId = null;
      _selectedTopicUnitName = null;
      _editingTopicId = null;
      _topicActive = true;
    });
  }

  // ------------------------------------------------------------
  // MAIN SCREEN
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateSyllabusBloc, CreateSyllabusState>(
      bloc: _bloc,
      listener: _handleSyllabusState,
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF0F6),
        appBar: AppBar(
          backgroundColor: AppTheme.primaryViolet,
          foregroundColor: Colors.white,
          title: const Text('Create Syllabus'),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTabs(),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child:
                    _selectedTab == 0
                        ? _buildUnitTab(key: const ValueKey('unit'))
                        : _buildTopicTab(key: const ValueKey('topic')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TAB BUTTONS
  // ------------------------------------------------------------

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          _tabButton('Syllabus Unit', 0),
          _tabButton('Syllabus Topic', 1),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = _selectedTab == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? _primary : _grey,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              fontFamily: 'Nunito',
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SYLLABUS UNIT TAB
  // ------------------------------------------------------------

  Widget _buildUnitTab({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Syllabus Unit Details',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _dark,
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Add a unit to the selected syllabus.',
                style: TextStyle(
                  fontSize: 12,
                  color: _grey,
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 18),
              _buildSubjectDropdown(
                label: 'Syllabus Name',
                value: _selectedSubjectId,
                hint: 'Please select a subject',
                onChanged: _onSubjectChanged,
                enabled: !_isSavingUnit,
              ),
              const SizedBox(height: 16),
              _fieldLabel('Unit No.'),
              _textField(
                controller: _unitNumberController,
                hint: 'Enter unit number',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !_isSavingUnit,
              ),
              const SizedBox(height: 16),
              _fieldLabel('Unit Name'),
              _textField(
                controller: _unitNameController,
                hint: 'Enter unit name',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 .-]')),
                ],
                enabled: !_isSavingUnit,
              ),
              const SizedBox(height: 8),
              _activeSwitch(
                value: _unitActive,
                onChanged: (value) {
                  setState(() {
                    _unitActive = value;
                  });
                },
              ),
              const SizedBox(height: 14),
              _actionButtons(
                primaryLabel:
                    _isSavingUnit
                        ? 'Saving...'
                        : _editingUnitId == null
                        ? 'Create'
                        : 'Update',
                onPrimary: _saveSyllabusUnit,
                onCancel: _cancelUnitForm,
                enabled: !_isSavingUnit && !_isLoadingUnits,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Syllabus Units',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _dark,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                  Text(
                    '${_loadedUnits.length} units',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _grey,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_isLoadingSubjects)
                const _LoadingView()
              else if (_facultySubjects.isEmpty)
                const _EmptyView(message: 'No subjects available.')
              else if (_selectedSubjectId == null)
                const _EmptyView(
                  message: 'Select a syllabus to view its units.',
                )
              else if (_isLoadingUnits)
                const _LoadingView()
              else if (_loadedUnits.isEmpty)
                const _EmptyView(message: 'No syllabus units found.')
              else
                ..._loadedUnits.map(_buildApiUnitCard),
            ],
          ),
        ),
      ],
    );
  }

  // Subject dropdown (list opens below the field)
  Widget _buildSubjectDropdown({
    required String label,
    required int? value,
    required ValueChanged<int?> onChanged,
    required String hint,
    bool enabled = true,
  }) {
    final safeValue =
        _facultySubjects.any((subject) => subject.id == value) ? value : null;

    return AppDropdown<int>(
      label: label,
      required: false,
      hint: _isLoadingSubjects ? 'Loading subjects...' : hint,
      value: safeValue,
      items: [
        for (final subject in _facultySubjects)
          AppDropdownItem(value: subject.id, label: subject.subjectName),
      ],
      enabled: enabled && !_isLoadingSubjects && _facultySubjects.isNotEmpty,
      onChanged: onChanged,
    );
  }

  Widget _buildApiUnitCard(SyllabusUnit unit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border, width: 1.1),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              unit.unitNo,
              style: const TextStyle(
                color: _primary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'Nunito',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unit.unitName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _dark,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  unit.active ? 'Status: Active' : 'Status: Inactive',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _grey,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isSavingUnit ? null : () => _editUnit(unit),
            tooltip: 'Edit unit',
            icon: const Icon(Icons.edit_outlined, color: _grey, size: 20),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SYLLABUS TOPIC TAB
  // ------------------------------------------------------------

  Widget _buildTopicTab({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Syllabus Topic Details',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _dark,
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Add a topic under a syllabus unit.',
                style: TextStyle(
                  fontSize: 12,
                  color: _grey,
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 18),
              _buildSubjectDropdown(
                label: 'Syllabus Name',
                value: _selectedTopicSubjectId,
                hint: 'Please select a subject',
                onChanged: _onTopicSubjectChanged,
                enabled: !_isSavingTopic,
              ),
              const SizedBox(height: 16),
              AppDropdown<int>(
                label: 'Unit Name',
                required: false,
                hint:
                    _isLoadingUnits
                        ? 'Loading units...'
                        : (_topicUnits.isEmpty
                            ? 'No units available'
                            : 'Please select a unit name'),
                value:
                    _topicUnits.any((unit) => unit.id == _selectedTopicUnitId)
                        ? _selectedTopicUnitId
                        : null,
                items: [
                  for (final unit in _topicUnits)
                    AppDropdownItem(value: unit.id, label: unit.unitName),
                ],
                enabled: !_isSavingTopic && !_isLoadingUnits,
                onChanged: _onTopicUnitChanged,
              ),
              const SizedBox(height: 16),
              _fieldLabel('Topic Number'),
              _textField(
                controller: _topicNumberController,
                hint: 'Enter topic number',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !_isSavingTopic,
              ),
              const SizedBox(height: 16),
              _fieldLabel('Topic Name'),
              _textField(
                controller: _topicNameController,
                hint: 'Enter topic name',
                enabled: !_isSavingTopic,
              ),
              const SizedBox(height: 16),
              _fieldLabel('Description'),
              _textField(
                controller: _descriptionController,
                hint: 'Enter description',
                maxLines: 4,
                enabled: !_isSavingTopic,
              ),
              const SizedBox(height: 16),
              _fieldLabel('No. of Lectures'),
              _textField(
                controller: _lectureCountController,
                hint: 'Enter number of lectures',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !_isSavingTopic,
              ),
              const SizedBox(height: 8),
              _activeSwitch(
                value: _topicActive,
                onChanged:
                    _isSavingTopic
                        ? (_) {}
                        : (value) => setState(() => _topicActive = value),
              ),
              const SizedBox(height: 14),
              _actionButtons(
                primaryLabel:
                    _isSavingTopic
                        ? 'Saving...'
                        : (_editingTopicId == null ? 'Submit' : 'Update'),
                onPrimary: _saveSyllabusTopic,
                onCancel: _cancelTopicForm,
                enabled:
                    !_isSavingTopic && !_isLoadingTopics && !_isLoadingUnits,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Syllabus Topics',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _dark,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                  Text(
                    '${_topics.length} topics',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _grey,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_isLoadingTopics)
                const _LoadingView()
              else if (_selectedTopicUnitId == null)
                const _EmptyView(
                  message: 'Select a syllabus and unit to view topics.',
                )
              else if (_topics.isEmpty)
                const _EmptyView(message: 'No syllabus topics found.')
              else
                ..._topics.map(_buildApiTopicCard),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApiTopicCard(SyllabusTopic topic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border, width: 1.1),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              topic.topicNumber,
              style: const TextStyle(
                color: _primary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'Nunito',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.topicName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _dark,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito',
                  ),
                ),
                if (topic.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    topic.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _grey,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  'Lectures: ${topic.noOfLectures} • ${topic.active ? 'Active' : 'Inactive'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _grey,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isSavingTopic ? null : () => _editTopic(topic),
            tooltip: 'Edit topic',
            icon: const Icon(Icons.edit_outlined, color: _grey, size: 20),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // COMMON CARD
  // ------------------------------------------------------------

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ------------------------------------------------------------
  // FIELD LABEL
  // ------------------------------------------------------------

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: _dark,
          fontWeight: FontWeight.w700,
          fontFamily: 'Nunito',
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TEXT FIELD
  // ------------------------------------------------------------

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      enabled: enabled,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: _dark,
        fontFamily: 'Nunito',
      ),
      decoration: _inputDecoration(context: context, hint: hint),
    );
  }

  // ------------------------------------------------------------
  // ACTIVE SWITCH
  // ------------------------------------------------------------

  Widget _activeSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Switch.adaptive(
          value: value,
          activeColor: _primary,
          onChanged: onChanged,
        ),
        const SizedBox(width: 4),
        const Text(
          'Active',
          style: TextStyle(fontSize: 13, color: _dark, fontFamily: 'Nunito'),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // ACTION BUTTONS
  // ------------------------------------------------------------

  Widget _actionButtons({
    required String primaryLabel,
    required VoidCallback onPrimary,
    required VoidCallback onCancel,
    bool enabled = true,
  }) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: enabled ? onPrimary : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _grey.withOpacity(0.12),
              disabledForegroundColor: _grey,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              primaryLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: enabled ? onCancel : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: _grey,
              side: const BorderSide(color: _border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Nunito')),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// LOADING VIEW
// ------------------------------------------------------------

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

// ------------------------------------------------------------
// EMPTY VIEW
// ------------------------------------------------------------

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontFamily: 'Nunito',
          ),
        ),
      ),
    );
  }
}
