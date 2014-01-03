part of crowdy;

class OutputSegmentUI {

  bool removable;
  html.LIElement segment;
  html.SpanElement name;
  html.SpanElement value;
  html.ButtonElement deleteButton;

  OutputSegmentUI(String defaultName, bool this.removable, bool editable) {
    if (this.removable) {
      this.deleteButton = new html.ButtonElement()
      ..text = 'Delete'
      ..className = 'btn btn-danger'
      ..onClick.listen((e) => this._remove());
    }

    this.segment = new html.LIElement();

    this.name = new html.SpanElement()
    ..text = defaultName.isNotEmpty ? defaultName : 'segment-name'
    ..contentEditable = editable.toString()
    ..attributes['onKeyPress'] = editable ? 'return (this.innerText.length <= 32)' : 'return';

    this.value = new html.SpanElement();
    this.value.className = 'example';
  }

  html.LIElement getFormElement(String exampleValue) {
    this.segment.appendHtml('<span>"</span>');
    this.segment.append(this.name);
    this.segment.appendHtml('<span>"</span>');

    if (exampleValue.isNotEmpty) {
      this.value.text = 'e.g. ${exampleValue}';
      this.segment.append(this.value);
    }

    if (this.removable) {
      html.DivElement buttonDiv = new html.DivElement();
      buttonDiv.className = 'col-sm-2';
      buttonDiv.append(this.deleteButton);
      this.segment.append(buttonDiv);
    }

    return this.segment;
  }

  void _remove() {
    this.segment.remove();
  }
}

class BaseSpecification {

  String id;
  Map<String, OutputSegmentUI> elements;
  html.HeadingElement title;
  html.DivElement view;
  html.DivElement innerView;
  html.UListElement elementList;

  BaseSpecification(String this.id) {
    this.elements = new Map<String, OutputSegmentUI>();
    this.view = new html.DivElement();
    this.innerView = new html.DivElement();
    this.elementList = new html.UListElement();
    this.initialize();
  }

  void initialize() {
    this.view.id = '${this.id}-specification';
    this.view.className = 'output-specification';
    this.elementList.className = 'segment-list';

    this.title = new html.HeadingElement.h4();
    this.title.text = 'Output Specification ';
    this.title.className = 'margin-top';
    this.view.append(this.title);
    this.view.append(new html.HRElement());

    this.innerView.append(new html.ParagraphElement()..text = '{');
    this.innerView.append(this.elementList);
    this.innerView.append(new html.ParagraphElement()..text = '}');
    this.view.append(this.innerView);
  }


  void addElement(String identifier,
                  {String defaultName: '', String example: '', bool editable: true,
                    bool removable: false, Map<String, String> additional: null}) {
    OutputSegmentUI newElement = new OutputSegmentUI(defaultName, removable, editable);
    newElement.name.id = identifier;
    this.elements[identifier] = newElement;
    this.elementList.append(newElement.getFormElement(example));
  }

  void editElement(String identifier, String newText) {
    this.elements[identifier].name.text = newText;
  }

  void removeElement(String identifier) {
    this.elements[identifier]._remove();
    this.elements.remove(identifier);
  }

  void clear() {
    this.elementList.innerHtml = '';
    this.elements.clear();
  }

  html.SelectElement select(Map<String, bool> previousConnections) {
    html.SelectElement selectElement = new html.SelectElement();
    selectElement.className = 'output-segments';
    if (previousConnections.length > 0) {
      Map<String, OutputSegmentUI> segmentList = operators[previousConnections.keys.first].details.output.elements;
      segmentList.forEach((identifier, segment) => selectElement.append(new html.OptionElement(data: segment.name.text, value: segment.name.id)));
    }
    //selectElement.onChange.listen((e) => selectElement.dataset['segment'] = e.)
    return selectElement;
  }
}

class OutputSpecification extends BaseSpecification {

  OutputSpecification(String id) : super(id) {

  }

  bool refresh (Map<String, OutputSegmentUI> previousElements) {
    bool changed = false;
    for (int i = 0; i < previousElements.length; i++) {
      changed = this.updateSegment(previousElements.keys.elementAt(i), previousElements.values.elementAt(i)) || changed;
    }
    //previousElements.forEach((id, segment) => changed = this.updateSegment(id, segment)) || changed;
    //this.elements.forEach((id, segment) => assureSegment(id, segment, previousElements));
    for (int i = this.elements.length-1; i >= 0; i--) {
      changed = this.assureSegment(this.elements.keys.elementAt(i), this.elements.values.elementAt(i), previousElements) || changed;
    }
    return changed;
  }

  bool updateSegment(String id, OutputSegmentUI segment) {
    if (!this.elements.containsKey(id)) {
      this.addElement(segment.name.id, defaultName: segment.name.text, editable: false);
      return true;
    }

    if (this.elements[id].name.text.compareTo(segment.name.text) != 0) {
      this.editElement(id, segment.name.text);
      return true;
    }

    return false;
  }

  bool assureSegment(String id, OutputSegmentUI segment, Map<String, OutputSegmentUI> previousElements) {
    if (!previousElements.containsKey(id)) {
      this.removeElement(segment.name.id);
      return true;
    }
    return false;
  }
}

class InputHumanOutputSpecification extends OutputSpecification {

  InputHumanOutputSpecification(String id) : super(id) {

  }
}

class InputManualOutputSpecification extends OutputSpecification {

  InputManualOutputSpecification(String id) : super(id) {

  }
}

class SelectionOutputSpecification extends OutputSpecification {

  SelectionDetailsUI details;

  SelectionOutputSpecification(SelectionDetailsUI this.details, String id) : super(id) {

  }

  bool refresh (Map<String, OutputSegmentUI> previousElements) {
    bool updated = super.refresh(previousElements);
    if (updated) {
      this.details.parametersView.querySelectorAll('.rule select.output-segments').forEach((html.SelectElement e) => _updateRuleSegments(e));
    }

    return updated;
  }

  void _updateRuleSegments(html.SelectElement e) {
    String selectedSegment = e.value;
    e.children.clear();
    e.children.addAll(this.select(this.details.prevConn).options);
    e.value = selectedSegment;
  }
}

class SortOutputSpecification extends OutputSpecification {

  SortDetailsUI details;

  SortOutputSpecification(SortDetailsUI this.details, String id) : super(id) {

  }
  /*
  bool refresh (Map<String, OutputSegmentUI> previousElements) {
    bool updated = super.refresh(previousElements);
    if (updated) {
      this.details.parametersView.querySelectorAll('.rule select.output-segments').forEach((html.SelectElement e) => _updateRuleSegments(e));
    }

    return updated;
  }

  void _updateRuleSegments(html.SelectElement e) {
    String selectedSegment = e.value;
    e.children.clear();
    e.children.addAll(this.select(this.details.prevConn).options);
    e.value = selectedSegment;
  }*/
}

class SplitOutputSpecification extends OutputSpecification {

  SplitDetailsUI details;

  SplitOutputSpecification(SplitDetailsUI this.details, String id) : super(id) {

  }
  /*
  bool refresh (Map<String, OutputSegmentUI> previousElements) {
    bool updated = super.refresh(previousElements);
    if (updated) {
      this.details.parametersView.querySelectorAll('.rule select.output-segments').forEach((html.SelectElement e) => _updateRuleSegments(e));
    }

    return updated;
  }

  void _updateRuleSegments(html.SelectElement e) {
    String selectedSegment = e.value;
    e.children.clear();
    e.children.addAll(this.select(this.details.prevConn).options);
    e.value = selectedSegment;
  }*/
}