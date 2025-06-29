import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task.dart';
import '../providers/task_provider.dart';
import '../../../../shared/services/ai_agent_service.dart';

/// タスク追加ダイアログ
class AddTaskDialog extends ConsumerStatefulWidget {
  const AddTaskDialog({super.key});

  @override
  ConsumerState<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends ConsumerState<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskDifficulty _selectedDifficulty = TaskDifficulty.medium;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _hasTime = false;
  int _estimatedDuration = 60;
  
  // サブタスク関連
  final List<SubTask> _subTasks = [];
  final _subTaskController = TextEditingController();

  // AI分析関連
  final _aiInputController = TextEditingController();
  bool _isAiAnalyzing = false;
  bool _hasAiAnalyzed = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subTaskController.dispose();
    _aiInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
            // 固定ヘッダー
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add_task,
                      color: Colors.blue[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '新しいタスク',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        Text(
                          'AIが分析をサポートします',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_hasAiAnalyzed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
            children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[600],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'AI分析済み',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // スクロール可能なコンテンツ
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                key: _formKey,
                child: _buildFormFields(),
              ),
              ),
            ),
            
            // 固定フッター（ボタン）
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('キャンセル'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _createTask,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('作成'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
              ),
            ],
          ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // AI分析セクション
        _buildAiAnalysisSection(),
        const SizedBox(height: 24),
        
        // タイトル
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'タイトル *',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'タイトルを入力してください';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // 説明
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: '説明',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        
        // 日付
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('日付'),
          subtitle: Text(
            '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
          ),
          onTap: () => _selectDate(context),
        ),
        
        // 時間
        CheckboxListTile(
          title: const Text('時間を設定'),
          value: _hasTime,
          onChanged: (value) {
            setState(() {
              _hasTime = value ?? false;
            });
          },
        ),
        if (_hasTime) ...[
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('時間'),
            subtitle: Text(_selectedTime.format(context)),
            onTap: () => _selectTime(context),
          ),
          const SizedBox(height: 8),
        ],
        
        // 予想時間
        ListTile(
          leading: const Icon(Icons.timer),
          title: const Text('予想時間'),
          subtitle: Text('$_estimatedDuration分'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  if (_estimatedDuration > 15) {
                    setState(() {
                      _estimatedDuration -= 15;
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    _estimatedDuration += 15;
                  });
                },
              ),
            ],
          ),
        ),
        
        // 優先度
        ListTile(
          leading: const Icon(Icons.priority_high),
          title: const Text('優先度'),
          trailing: DropdownButton<TaskPriority>(
            value: _selectedPriority,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedPriority = value;
                });
              }
            },
            items: TaskPriority.values.map((priority) {
              return DropdownMenuItem(
                value: priority,
                child: Text(priority.label),
              );
            }).toList(),
          ),
        ),
        
        // 難易度
        ListTile(
          leading: const Icon(Icons.trending_up),
          title: const Text('難易度'),
          trailing: DropdownButton<TaskDifficulty>(
            value: _selectedDifficulty,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedDifficulty = value;
                });
              }
            },
            items: TaskDifficulty.values.map((difficulty) {
              return DropdownMenuItem(
                value: difficulty,
                child: Text(difficulty.label),
              );
            }).toList(),
          ),
        ),
        
        // サブタスク
        const SizedBox(height: 16),
        _buildSubTasksSection(),
      ],
    );
  }

  Widget _buildSubTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.checklist, size: 20),
            const SizedBox(width: 8),
            const Text(
              'サブタスク',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addSubTask,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('追加'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_subTasks.isNotEmpty) ...[
          ..._subTasks.asMap().entries.map((entry) {
            final index = entry.key;
            final subTask = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  Icons.check_circle_outline,
                  color: Colors.grey[600],
                ),
                title: Text(subTask.title),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeSubTask(index),
                ),
                dense: true,
              ),
            );
          }).toList(),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'サブタスクがありません',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _createTask() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_titleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('タイトルを入力してください')),
        );
        return;
      }

      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _hasTime ? _selectedTime.hour : 0,
        _hasTime ? _selectedTime.minute : 0,
      );

      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        createdAt: DateTime.now(),
        scheduledDate: scheduledDateTime,
        scheduledTimeStart: _hasTime ? scheduledDateTime : null,
        scheduledTimeEnd: _hasTime 
            ? scheduledDateTime.add(Duration(minutes: _estimatedDuration))
            : null,
        estimatedDuration: _estimatedDuration,
        priority: _selectedPriority,
        difficulty: _selectedDifficulty,
        subTasks: _subTasks,
      );

      ref.read(taskProvider.notifier).createTask(task);
      Navigator.of(context).pop();
    }
  }

  void _addSubTask() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('サブタスクを追加'),
        content: TextField(
          controller: _subTaskController,
          decoration: const InputDecoration(
            labelText: 'サブタスク名',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _subTaskController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = _subTaskController.text.trim();
              if (title.isNotEmpty) {
                setState(() {
                  _subTasks.add(SubTask(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                  ));
                });
                _subTaskController.clear();
              }
              Navigator.of(context).pop();
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  void _removeSubTask(int index) {
    setState(() {
      _subTasks.removeAt(index);
    });
  }

  Widget _buildAiAnalysisSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: Colors.blue[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AI分析',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
              const Spacer(),
              if (_hasAiAnalyzed)
                Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '自然言語でタスクを入力すると、AIが詳細を自動分析します',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _aiInputController,
            decoration: InputDecoration(
              hintText: '例: 明日までにプレゼン資料を作成する',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              suffixIcon: _isAiAnalyzing
                  ? Container(
                      width: 20,
                      height: 20,
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                      ),
                    )
                  : IconButton(
                      icon: Icon(Icons.auto_awesome, color: Colors.blue[600]),
                      onPressed: _aiInputController.text.trim().isNotEmpty && !_isAiAnalyzing
                          ? _analyzeWithAi
                          : null,
                      tooltip: 'AI分析',
                    ),
            ),
            maxLines: 2,
            onChanged: (value) {
              setState(() {}); // ボタンの有効化/無効化のため
            },
            onSubmitted: (value) {
              if (value.trim().isNotEmpty && !_isAiAnalyzing) {
                _analyzeWithAi();
              }
            },
          ),
          const SizedBox(height: 8),
          if (_hasAiAnalyzed) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI分析が完了しました。内容を確認してください。',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _analyzeWithAi() async {
    final input = _aiInputController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isAiAnalyzing = true;
    });

    try {
      final result = await AIAgentService.analyzeTask(userInput: input);
      
      // 分析結果でフォームフィールドを更新
      setState(() {
        _titleController.text = result.title;
        _descriptionController.text = result.description;
        _estimatedDuration = result.estimatedDuration;
        
        // 優先度の変換
        switch (result.priority.toLowerCase()) {
          case 'low':
          case '1':
            _selectedPriority = TaskPriority.low;
            break;
          case 'medium':
          case '2':
          case '3':
            _selectedPriority = TaskPriority.medium;
            break;
          case 'high':
          case '4':
            _selectedPriority = TaskPriority.high;
            break;
          case 'urgent':
          case '5':
            _selectedPriority = TaskPriority.urgent;
            break;
          default:
            _selectedPriority = TaskPriority.medium;
        }
        
        // 複雑さの変換
        switch (result.complexity.toLowerCase()) {
          case 'easy':
          case 'simple':
            _selectedDifficulty = TaskDifficulty.easy;
            break;
          case 'medium':
          case 'moderate':
            _selectedDifficulty = TaskDifficulty.medium;
            break;
          case 'hard':
          case 'difficult':
            _selectedDifficulty = TaskDifficulty.hard;
            break;
          case 'expert':
          case 'complex':
            _selectedDifficulty = TaskDifficulty.expert;
            break;
          default:
            _selectedDifficulty = TaskDifficulty.medium;
        }
        
        // タグからサブタスクを生成（オプション）
        if (result.suggestions.isNotEmpty) {
          _subTasks.clear();
          for (int i = 0; i < result.suggestions.length && i < 3; i++) {
            _subTasks.add(SubTask(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_$i',
              title: result.suggestions[i],
            ));
          }
        }
        
        _hasAiAnalyzed = true;
        _isAiAnalyzing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('AI分析が完了しました！内容を確認してください。'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAiAnalyzing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('AI分析に失敗しました: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
} 