class PriorityQueueEntry<E> {
  final E element;
  final double priority;

  const PriorityQueueEntry(this.element, this.priority);
}

class PriorityQueue<E> {
  final List<PriorityQueueEntry<E>> _heap = [];

  bool get isEmpty => _heap.isEmpty;
  bool get isNotEmpty => _heap.isNotEmpty;
  int get length => _heap.length;

  void enqueue(E element, double priority) {
    _heap.add(PriorityQueueEntry(element, priority));
    _bubbleUp(_heap.length - 1);
  }

  E dequeue() {
    if (_heap.isEmpty) {
      throw StateError('Cannot dequeue from empty priority queue');
    }
    final result = _heap.first.element;
    final last = _heap.removeLast();
    if (_heap.isNotEmpty) {
      _heap[0] = last;
      _bubbleDown(0);
    }
    return result;
  }

  E peek() {
    if (_heap.isEmpty) {
      throw StateError('Cannot peek an empty priority queue');
    }
    return _heap.first.element;
  }

  void clear() {
    _heap.clear();
  }

  void _bubbleUp(int index) {
    var currentIndex = index;
    while (currentIndex > 0) {
      final parentIndex = (currentIndex - 1) >> 1;
      if (_heap[currentIndex].priority < _heap[parentIndex].priority) {
        final temp = _heap[currentIndex];
        _heap[currentIndex] = _heap[parentIndex];
        _heap[parentIndex] = temp;
        currentIndex = parentIndex;
      } else {
        break;
      }
    }
  }

  void _bubbleDown(int index) {
    var currentIndex = index;
    final length = _heap.length;

    while (true) {
      final leftChildIndex = (currentIndex << 1) + 1;
      final rightChildIndex = leftChildIndex + 1;
      var smallestIndex = currentIndex;

      if (leftChildIndex < length &&
          _heap[leftChildIndex].priority < _heap[smallestIndex].priority) {
        smallestIndex = leftChildIndex;
      }

      if (rightChildIndex < length &&
          _heap[rightChildIndex].priority < _heap[smallestIndex].priority) {
        smallestIndex = rightChildIndex;
      }

      if (smallestIndex != currentIndex) {
        final temp = _heap[currentIndex];
        _heap[currentIndex] = _heap[smallestIndex];
        _heap[smallestIndex] = temp;
        currentIndex = smallestIndex;
      } else {
        break;
      }
    }
  }
}
