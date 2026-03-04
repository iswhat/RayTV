interface FocusableElement {
  id: string;
  group?: string;
  x: number;
  y: number;
  onFocus: () => void;
  onBlur: () => void;
  onClick?: () => void;
}

class FocusManager {
  private focusedElement: string | null = null;
  private focusableElements: Map<string, FocusableElement> = new Map();
  private focusGroups: Map<string, Set<string>> = new Map();
  private currentGroup: string | null = null;

  registerElement(element: FocusableElement): void {
    this.focusableElements.set(element.id, element);
    
    if (element.group) {
      if (!this.focusGroups.has(element.group)) {
        this.focusGroups.set(element.group, new Set());
      }
      this.focusGroups.get(element.group)?.add(element.id);
    }
  }

  unregisterElement(id: string): void {
    const element = this.focusableElements.get(id);
    if (element && element.group) {
      this.focusGroups.get(element.group)?.delete(id);
    }
    this.focusableElements.delete(id);
    if (this.focusedElement === id) {
      this.focusedElement = null;
    }
  }

  focusElement(id: string): void {
    if (!this.focusableElements.has(id)) {
      return;
    }

    // Blur current element
    if (this.focusedElement) {
      const currentElement = this.focusableElements.get(this.focusedElement);
      currentElement?.onBlur();
    }

    // Focus new element
    const newElement = this.focusableElements.get(id);
    if (newElement) {
      newElement.onFocus();
      this.focusedElement = id;
      this.currentGroup = newElement.group || null;
    }
  }

  focusNext(direction: 'up' | 'down' | 'left' | 'right'): void {
    if (!this.focusedElement) {
      // Focus first element if none is focused
      const firstElement = this.focusableElements.keys().next().value;
      if (firstElement) {
        this.focusElement(firstElement);
      }
      return;
    }

    const currentElement = this.focusableElements.get(this.focusedElement);
    if (!currentElement) return;

    let candidates: FocusableElement[] = [];
    
    // Get elements in the same group if applicable
    if (currentElement.group) {
      const groupElements = this.focusGroups.get(currentElement.group);
      if (groupElements) {
        candidates = Array.from(groupElements).map(id => this.focusableElements.get(id)!).filter(Boolean);
      }
    } else {
      // Otherwise, use all elements
      candidates = Array.from(this.focusableElements.values());
    }

    // Filter out current element
    candidates = candidates.filter(element => element.id !== this.focusedElement);

    if (candidates.length === 0) return;

    // Find the closest element in the specified direction
    let closestElement: FocusableElement | null = null;
    let closestDistance = Infinity;

    for (const candidate of candidates) {
      let distance: number;
      
      switch (direction) {
        case 'up':
          if (candidate.y < currentElement.y) {
            distance = currentElement.y - candidate.y;
          } else {
            continue;
          }
          break;
        case 'down':
          if (candidate.y > currentElement.y) {
            distance = candidate.y - currentElement.y;
          } else {
            continue;
          }
          break;
        case 'left':
          if (candidate.x < currentElement.x) {
            distance = currentElement.x - candidate.x;
          } else {
            continue;
          }
          break;
        case 'right':
          if (candidate.x > currentElement.x) {
            distance = candidate.x - currentElement.x;
          } else {
            continue;
          }
          break;
      }

      // For horizontal directions, also consider vertical distance
      if (direction === 'left' || direction === 'right') {
        distance += Math.abs(candidate.y - currentElement.y) * 0.5;
      }
      // For vertical directions, also consider horizontal distance
      if (direction === 'up' || direction === 'down') {
        distance += Math.abs(candidate.x - currentElement.x) * 0.5;
      }

      if (distance < closestDistance) {
        closestDistance = distance;
        closestElement = candidate;
      }
    }

    if (closestElement) {
      this.focusElement(closestElement.id);
    }
  }

  handleKeyEvent(key: string): void {
    switch (key) {
      case 'ArrowUp':
        this.focusNext('up');
        break;
      case 'ArrowDown':
        this.focusNext('down');
        break;
      case 'ArrowLeft':
        this.focusNext('left');
        break;
      case 'ArrowRight':
        this.focusNext('right');
        break;
      case 'Enter':
      case ' ':  // Space key
        if (this.focusedElement) {
          const element = this.focusableElements.get(this.focusedElement);
          element?.onClick?.();
        }
        break;
    }
  }

  getFocusedElement(): string | null {
    return this.focusedElement;
  }

  clearFocus(): void {
    if (this.focusedElement) {
      const element = this.focusableElements.get(this.focusedElement);
      element?.onBlur();
      this.focusedElement = null;
      this.currentGroup = null;
    }
  }

  reset(): void {
    this.clearFocus();
    this.focusableElements.clear();
    this.focusGroups.clear();
    this.currentGroup = null;
  }
}

// Export a singleton instance
export const focusManager = new FocusManager();
export default FocusManager;