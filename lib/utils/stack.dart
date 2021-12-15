import 'dart:collection';

class Stack<T> { 
  final stack = Queue<T>(); 

  void push(T element) {
    stack.addLast(element);
  }

  T pop() {
    final T lastElement = stack.last;
    stack.removeLast();
    return lastElement;
  }

  T peek() {
    return stack.last;
  }

  bool isEmpty() {
    return stack.isEmpty;
  }

  void clear() {
    stack.clear();
  }
}

