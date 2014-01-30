part of crowdy;

class ElementUI {
  String id, type;
  html.LabelElement label;
  html.HtmlElement input;

  ElementUI(String this.id, String this.type, String description,
      {Map<String, String> attributes: null, List<String> options: null}) {
    this.label = new html.LabelElement()
    ..text = description
    ..htmlFor = this.id
    ..className = 'col-sm-3 control-label';

    switch (this.type) {
      case 'button':
        this.input = new html.ButtonElement();
        break;
      case 'editable':
        this.input = new html.DivElement()
        ..contentEditable = 'true';
        break;
      case 'list':
        this.input = new html.UListElement();
        break;
      case 'select':
        this.input = new html.SelectElement();
        for(int i = 0; i < options.length; i++) {
          html.OptionElement newOption = new html.OptionElement(data: options[i], value: '$i');
          this.input.append(newOption);
        }
        break;
      case 'textarea':
        this.input = new html.TextAreaElement();
        this.input.onKeyDown.listen(_tabbableTextAreaKeyPressed);
        break;
      default:
        this.input = new html.InputElement(type: this.type);
        break;
    }

    if (attributes != null) {
      attributes.forEach((property, value) => this.input.attributes[property] = value);
    }

    this.input.id = this.id;
    if (this.input.className.isEmpty) {
      this.input.className = 'form-control';
    }
  }

  html.DivElement getFormElement() {
    html.DivElement inputDiv = new html.DivElement()
    ..className = 'col-sm-9'
    ..append(this.input);

    html.DivElement outerDiv = new html.DivElement()
    ..className = 'row'
    ..hidden = this.type == 'list'
    ..append(this.label)
    ..append(inputDiv);

    return outerDiv;
  }

}

class BaseDetailsUI {

  final Logger log = new Logger('OperatorDetails');

  static int count = 1;

  String id, type;
  Map<String, bool> prevConn, nextConn;
  BaseSpecification output;

  Map<String, ElementUI> base;
  Map<String, ElementUI> elements;
  html.DivElement view;
  html.DivElement detailsViewOuter;
  html.DivElement parametersViewOuter;
  html.DivElement detailsView;
  html.DivElement parametersView;

  BaseDetailsUI(String this.id, String this.type, Map<String, bool> this.prevConn, Map<String, bool> this.nextConn) {
    this.output = new OutputSpecification(this.id);

    this.base = new Map<String, ElementUI>();
    this.elements = new Map<String, ElementUI>();

    this.detailsViewOuter = new html.DivElement()..id = '${this.id}-details'..className = 'operator-details';
    this.detailsView = new html.DivElement()..className = 'inner';
    this.parametersViewOuter = new html.DivElement()..id = '${this.id}-parameters'..className = 'operator-parameters';
    this.parametersView = new html.DivElement()..className = 'inner';
    this.view = new html.DivElement()..append(this.detailsViewOuter)..append(this.parametersViewOuter);
  }

  void initialize() {
    this.addTitles();
    this.addElement('id', 'text', 'ID', this.base, features: {'disabled': 'true', 'value': this.id});
    this.addElement('type', 'text', 'Type', this.base, features: {'disabled': 'true', 'value': this.type});
    this.addElement('name', 'text', 'Name', this.base);
    this.addElement('description', 'textarea', 'Description', this.base, features: {'rows': '3'});
  }

  ElementUI addElement(String identifier, String type, String description, Map<String, ElementUI> list,
                  { Map<String, String> features: null, List<String> options: null }) {
    ElementUI newElement = new ElementUI('${this.id}_${count}', type, description, options: options, attributes: features);
    list[identifier] = newElement;
    count += 1;

    if (list == this.base) {
      this.detailsView.append(newElement.getFormElement());
    }
    else {
      this.parametersView.append(newElement.getFormElement());
    }

    return newElement;
  }

  void addTitles() {
    this.detailsViewOuter.append(new html.HeadingElement.h4()
    ..id = 'details'
    ..className = 'details-title'
    ..append(new html.SpanElement()
    ..text = 'Details'
    ..onClick.listen((e) => _triggerDetails(this.detailsView)))
    ..append(new html.SpanElement()
    ..appendHtml('<small>for bookkeeping purposes</small>')
    ..onClick.listen((e) => _triggerDetails(this.detailsView))));
    this.detailsViewOuter.append(new html.HRElement());
    this.detailsViewOuter.append(this.detailsView);

    this.parametersViewOuter.append(new html.HeadingElement.h4()
    ..id = 'parameters'
    ..className = 'details-title'
    ..append(new html.SpanElement()
    ..text = 'Parameters'
    ..onClick.listen((e) => _triggerDetails(this.parametersView)))
    ..append(new html.SpanElement()
    ..appendHtml('<small>specific to this operator</small>')
    ..onClick.listen((e) => _triggerDetails(this.parametersView))));
    this.parametersViewOuter.append(new html.HRElement());
    this.parametersViewOuter.append(this.parametersView);
  }

  bool refresh(OutputSpecification specification) {
    return false;
  }

  void clear() {
    this.output.clear();
  }

  void updateOperatorDetails() {
    this.base.forEach((id, element) => operators[this.id].updateDetail(id, element.input));
    this.elements.forEach((id, element) => operators[this.id].updateDetail(id, element.input));
  }
}

class OutputDetailsUI extends BaseDetailsUI {

  OutputDetailsUI(String id, String type, Map<String, bool> prevConn, Map<String, bool> nextConn) : super(id, type, prevConn, nextConn) {
    this.output = new OutputSpecification(this.id);
  }

  bool refresh(OutputSpecification specification) {
    return (this.output as OutputSpecification).refresh(specification.elements);
  }
}

class RuleDetailsUI extends OutputDetailsUI {

  html.DivElement rulesDiv;
  html.ButtonElement addRuleButton;

  RuleDetailsUI(String id, String type, Map<String, bool> prevConn, Map<String, bool> nextConn) : super(id, type, prevConn, nextConn) {
  }

  void initialize() {
    super.initialize();

    this.rulesDiv = new html.DivElement()
    ..className = 'rules';
    this.parametersView.append(this.rulesDiv);

    this.addRuleButton = new html.ButtonElement()
    ..className = 'btn btn-default btn-xs'
    ..text = 'add new rule'
    ..onClick.listen(_addRule);

    this.parametersViewOuter.querySelector('#parameters').append(this.addRuleButton);
  }

  void clear() {
    super.clear();
    this.rulesDiv.children.clear();
  }

  bool refresh(OutputSpecification specification) {
    bool updated = super.refresh(specification);
    if (specification.elements.length == 0) {
      this.clear();
      return true;
    }
    return updated;
  }

  void _addRule(html.MouseEvent e) { }

  void _deleteRule(html.MouseEvent e, String ruleId) {
    this.rulesDiv.querySelector('#${ruleId}').remove();
  }
}

class EnrichDetailsUI extends OutputDetailsUI {

  EnrichDetailsUI(String id, String type, Map<String, bool> prevConn, Map<String, bool> nextConn) : super(id, type, prevConn, nextConn) {
    this.view.append(this.output.view);
  }

  void initialize() {
    super.initialize();
    this.addElement('copy', 'number', 'Iterations', this.elements, features: {'min': '1', 'max': '5', 'value': '1'});
  }
}

class UnionDetailsUI extends OutputDetailsUI {

  UnionDetailsUI(String id, String type, Map<String, bool> prevConn, Map<String, bool> nextConn) : super(id, type, prevConn, nextConn) {
    this.view.append(this.output.view);
  }

  void initialize() {
    super.initialize();
  }
}

class SourceFileDetailsUI extends BaseDetailsUI {

  SourceFileDetailsUI(String id, String type, Map<String, bool> prevConn, Map<String, bool> nextConn) : super(id, type, prevConn, nextConn) {

  }

  void initialize() {
    super.initialize();
    this.addElement('input', 'file', 'File', this.elements);
    this.addElement('delimiter', 'text', 'Delimiter', this.elements);
  }
}

class SourceHumanDetailsUI extends BaseDetailsUI {

  static int count = 1;
  html.SelectElement availableInputs;
  html.DivElement elementsDiv;
  html.UListElement segmentList;

  List<html.DivElement> refreshableDivs;
  OutputSegmentUI _dragSegment;

  SourceHumanDetailsUI(String id, String type, Map<String, bool> prevConn, Map<String, bool> nextConn) : super(id, type, prevConn, nextConn) {
    this.output = new InputHumanOutputSpecification(this.id);
    this.view.append(this.output.view);
    closeHumanButton.onClick.listen(_onHumanClose);
  }

  void _onHumanClick(html.MouseEvent e) {
    modal.style.display = 'none';
    humanModal.classes.add('in');
    humanModal.style.display = 'block';
    humanModalBody
      ..append(new html.ParagraphElement()..className = 'lead'..appendHtml(this.refreshableDivs.elementAt(0).innerHtml))
      ..append(new html.ParagraphElement()..appendHtml(this.refreshableDivs.elementAt(1).innerHtml));

    this.parametersView.querySelectorAll('.rule').forEach((e) => _appendInputToPreview(e));
  }

  void _appendInputToPreview(html.Element e) {
    String type = e.querySelector('label').text;
    String name = e.dataset['segment'];
    if (type == 'text input') {
      humanModalBody.append(new html.ParagraphElement()
      ..append(new html.InputElement(type: 'text')..className = 'form-control'..name = name));
    }
    else if (type == 'number input') {
      List<html.InputElement> options = e.querySelectorAll('input');
      humanModalBody.append(new html.ParagraphElement()
      ..append(new html.InputElement(type: 'number')
      ..className = 'form-control'..name = name
      ..attributes['min'] = options.first.value
      ..attributes['max'] = options.last.value));
    }
    else if (type == 'single choice') {
      List<html.Element> options = e.querySelector('div.options').children;
      options.forEach((e) => humanModalBody.append(new html.DivElement()
      ..className = 'radio'
      ..append(new html.LabelElement()
      ..append(new html.InputElement(type: 'radio')..name = name)
      ..appendText(e.text))));
    }
    else if (type == 'multiple choice') {
      List<html.Element> options = e.querySelector('div.options').children;
      options.forEach((e) => humanModalBody.append(new html.DivElement()
      ..className = 'checkbox'
      ..append(new html.LabelElement()
      ..append(new html.InputElement(type: 'checkbox')..name = name)
      ..appendText(e.text))));
    }
  }

  void _onHumanClose(html.MouseEvent e) {
    humanModal.style.display = 'none';
    humanModal.querySelector('.modal-content .modal-body').children.clear();
    modal.classes.add('in');
    modal.style.display = 'block';
  }

  void initialize() {
    super.initialize();
    this.addElement('iteration', 'number', 'Number of copies', this.elements, features: {'value': '1', 'min': '1', 'max': '1000'});
    this.addElement('expiry', 'number', 'Max alloted time (sec)', this.elements, features: {'value': '60', 'min': '10', 'max': '300'});
    this.addElement('payment', 'number', 'Payment (¢)', this.elements, features: {'value': '10', 'min': '5', 'max': '300'});

    ElementUI previewButton = this.addElement('preview', 'button', '', this.elements);
    previewButton.input.text = 'Preview Human Task';
    previewButton.input..onClick.listen(_onHumanClick);

    this.addElement('segment-list', 'list', 'Available Segments', this.elements, features: {'class': 'list-inline segments'});
    ElementUI instructions = this.addElement('instructions', 'editable', 'Instructions for human workers', this.elements);
    ElementUI question = this.addElement('question', 'editable', 'Question', this.elements);
    this.configureHumanTasks();

    this.refreshableDivs = new List<html.DivElement>();
    instructions.input.onDrop.listen(_onSegmentDrop);
    instructions.input.onDragOver.listen(_onSegmentDragOver);
    question.input.onDrop.listen(_onSegmentDrop);
    question.input.onDragOver.listen(_onSegmentDragOver);
    this.refreshableDivs.add(instructions.input);
    this.refreshableDivs.add(question.input);
  }

  bool refresh(OutputSpecification specification) {
    this.segmentList.children.clear();
    Map<String, OutputSegmentUI> prevSegments = specification.elements;
    this.refreshableDivs.forEach((e) => this.refreshSegmentFromCurrent(e.querySelectorAll('span.segment-tag'), prevSegments));
    if (prevSegments.length > 0) {
      prevSegments.forEach((id, segment) => this.refreshSegmentFromPrevious(id, segment));
      this.segmentList.parent.parent.hidden = false;
    }
    else {
      this.segmentList.parent.parent.hidden = true;
    }
    return true;
  }

  void refreshSegmentFromPrevious(String id, OutputSegmentUI segment) {
    this.segmentList.append(
        new html.LIElement()
        ..append(new html.SpanElement()
        ..text = segment.name.text
        ..attributes['data-segment'] = segment.name.id
        ..className = 'segment-name'
        ..draggable = true
        ..onDrag.listen((e) => _dragSegment = segment)));
    this.refreshableDivs.forEach((e) => e.querySelectorAll('span[data-segment="$id"]').forEach((e) => e.querySelector('span.segment-name').text = segment.name.text));
  }

  void refreshSegmentFromCurrent(List<html.HtmlElement> segments, Map<String, OutputSegmentUI> prevSegments) {
    for (int i = segments.length-1; i >= 0; i--) {
      String segmentId = segments[i].attributes['data-segment'];
      if (!prevSegments.containsKey(segmentId)) {
        segments[i].remove();
      }
    }
  }

  void _onSegmentDrop(html.MouseEvent e) {
    String segmentId = _dragSegment.name.id;
    String segmentValue = _dragSegment.name.text;
    (e.target as html.HtmlElement).append(
        new html.SpanElement()
        ..attributes['data-segment'] = segmentId
        ..contentEditable = 'false'
        ..className = 'segment-tag'
        ..append(new html.SpanElement()
          ..text = segmentValue
          ..className = 'segment-name')
        ..append(
          new html.SpanElement()
          ..text = 'X'
          ..className = 'segment-remove'
          ..onClick.listen((e) => (e.target as html.SpanElement).parent.remove())));
  }

  void _onSegmentDragOver(html.MouseEvent e) {
    e.preventDefault();
  }

  void configureHumanTasks() {
    this.segmentList = this.parametersView.querySelector('ul');

    html.ButtonElement askInputFromUserButton = new html.ButtonElement()
    ..text = 'Ask for'
    ..className = 'btn btn-default btn-sm'
    ..onClick.listen(_addNewInput);

    this.availableInputs = new html.SelectElement()..className = 'form-control input-sm';
    SOURCE_OPTIONS_HUMAN_INPUTS.forEach((name, value) => this.availableInputs.append(new html.OptionElement(data: name, value: value)));

    html.DivElement buttonDiv = new html.DivElement()
    ..className = 'col-sm-3'
    ..append(askInputFromUserButton);
    //buttonDiv.appendText(' ');

    this.elementsDiv = new html.DivElement()
    ..className = 'col-sm-9'
    ..append(this.availableInputs);

    html.DivElement outerDiv = new html.DivElement()
    ..className = 'row'
    ..append(buttonDiv)
    ..append(this.elementsDiv);

    this.parametersView.append(outerDiv);
  }

  void _addNewInput(html.MouseEvent e) {
    html.DivElement ruleRow = new html.DivElement();
    ruleRow.className = 'row rule';
    ruleRow.attributes['data-segment'] = 'segment-${ruleRow.hashCode}';

    String inputDef = SOURCE_OPTIONS_HUMAN_INPUTS.keys.elementAt(this.availableInputs.selectedIndex);
    String inputType = SOURCE_OPTIONS_HUMAN_INPUTS[inputDef];
    this.output.addElement('segment-${ruleRow.hashCode}', example: '${inputDef} from human workers');

    html.DivElement elementRowDefinition = new html.DivElement()
    ..className = 'col-sm-3'
    ..append(new html.ButtonElement()
    ..text = '-'
    ..className = 'btn btn-danger btn-xs'
    ..onClick.listen((e) => _deleteInput(e, ruleRow.attributes['data-segment'])))
    ..append(new html.LabelElement()
    ..text = inputDef
    ..className = 'text-muted');
    ruleRow.append(elementRowDefinition);

    html.DivElement elementRowConfig = new html.DivElement()
    ..className = 'col-sm-9';

    switch (inputType) {
      case 'text':
        elementRowConfig.append(new html.InputElement(type: 'number')
                                  ..className = 'form-control input-sm'
                                  ..placeholder = 'max. character length'
                                  ..attributes['min'] = '1'
                                  ..attributes['max'] = '255');
        break;
      case 'number':
        elementRowConfig.append(new html.InputElement(type: 'number')
                                  ..placeholder = 'min. value'
                                  ..className = 'form-control input-sm input-xs');
        elementRowConfig.append(new html.InputElement(type: 'number')
                                  ..placeholder = 'max. value'
                                  ..className = 'form-control input-sm input-xs');
        break;
      case 'single':
      case 'multiple':
        html.DivElement newEditableDiv = this.getEditableDiv();
        this.refreshableDivs.add(newEditableDiv);
        elementRowConfig.append(newEditableDiv);
        break;
    }

    ruleRow.append(elementRowConfig);

    count += 1;
    this.parametersView.append(ruleRow);
  }

  html.DivElement getEditableDiv() {
    return new html.DivElement()
    ..contentEditable = 'true'
    ..className = 'form-control input-sm options'
    ..appendHtml('<div>Enter options line by line</div>')
    ..onDrop.listen(_onSegmentDrop)
    ..onDragOver.listen(_onSegmentDragOver);
  }

  void _deleteInput(html.MouseEvent e, String rowId) {
    this.parametersView.querySelector('div[data-segment="${rowId}"]').remove();
    this.output.removeElement(rowId);
  }
}

class SourceManualDetailsUI extends BaseDetailsUI {

  SourceManualDetailsUI(String id, String type, Map<String, bool> prevConn, Map<String, bool> nextConn) : super(id, type, prevConn, nextConn) {
    this.output = new InputManualOutputSpecification(this.id);
    this.output.title.append(new html.ButtonElement()
    ..text = '(re)generate'
    ..className = 'btn btn-default btn-xs'
    ..onClick.listen((e) => _onRefresh()));
    this.view.append(this.output.view);
  }

  void initialize() {
    super.initialize();
    this.addElement('input', 'textarea', 'Manual entry', this.elements, features: {'rows': '5'});
    this.addElement('delimiter', 'select', 'Delimiter', this.elements, options: SOURCE_OPTIONS_NAMES);
  }

  void _onRefresh() {
    String text = (this.elements['input'].input as html.TextAreaElement).value;
    String delimiter = SOURCE_OPTIONS_VALUES[int.parse((this.elements['delimiter'].input as html.SelectElement).value)];

    if (text.contains('\n')) {
      text = text.substring(0, text.indexOf('\n'));
    }

    this.output.clear();
    List<String> delimitedString;
    if (text.isNotEmpty && delimiter.isNotEmpty) {
      delimitedString = text.trim().split(delimiter);
    }
    else {
      delimitedString = new List<String>();
      delimitedString.add('');
    }

    for (String segment in delimitedString) {
      html.SpanElement dumpSpan = new html.SpanElement();
      this.output.addElement('segment-${dumpSpan.hashCode}', example: segment);
      dumpSpan.remove();
    }
  }
}

class SourceRSSDetailsUI extends BaseDetailsUI {

  SourceRSSDetailsUI(String id, String type, Map<String, bool> prevConn, Map<String, bool> nextConn) : super(id, type, prevConn, nextConn) {

  }

  void initialize() {
    super.initialize();
    this.addElement('webpage', 'url', 'Feed URL', this.elements);
  }
}

class SinkFileDetailsUI extends BaseDetailsUI {

  SinkFileDetailsUI(String id, String type, Map<String, bool> prevConn, Map<String, bool> nextConn) : super(id, type, prevConn, nextConn) {

  }

  void initialize() {
    super.initialize();
    this.addElement('output', 'text', 'File name', this.elements);
  }
}

class SinkEmailDetailsUI extends BaseDetailsUI {

  SinkEmailDetailsUI(String id, String type, Map<String, bool> prevConn, Map<String, bool> nextConn) : super(id, type, prevConn, nextConn) {

  }

  void initialize() {
    super.initialize();
    this.addElement('email', 'email', 'email address', this.elements);
  }
}

class ProcessingDetailsUI extends OutputDetailsUI {

  ProcessingDetailsUI(String id, String type, Map<String, bool> prevConn, Map<String, bool> nextConn) : super(id, type, prevConn, nextConn) {
    this.view.append(this.output.view);
  }

  void initialize() {
    super.initialize();
    this.addElement('input', 'textarea', 'Instructions', this.elements, features: {'rows': '5'});
  }
}

class SelectionDetailsUI extends RuleDetailsUI {

  static int count = 1;

  SelectionDetailsUI(String id, String type, Map<String, bool> prevConn, Map<String, bool> nextConn) : super(id, type, prevConn, nextConn) {
    this.output = new SelectionOutputSpecification(this, this.id);
    this.view.append(this.output.view);
  }

  void initialize() {
    super.initialize();
  }

  void _addRule(html.MouseEvent e) {
    if (this.prevConn.length < 1) {
      log.warning('Please first make sure there is an input flow to this operator.');
      return;
    }

    html.DivElement parameter = new html.DivElement()
    ..className = 'row rule'
    ..id = '${this.id}-rule-${count}';

    html.DivElement conditionDiv = new html.DivElement()
    ..className = 'col-sm-3'
    ..append(new html.ButtonElement()
    ..text = '-'
    ..className = 'btn btn-danger btn-xs'
    ..onClick.listen((e) => _deleteRule(e, parameter.id)))
    ..append(new html.LabelElement()
    ..text = 'Filter'
    ..className = 'text-muted');

    html.DivElement configDiv = new html.DivElement()
    ..className = 'col-sm-9'
    ..append(new html.UListElement()
      ..className = 'list-inline'
      ..append(new html.LIElement()
        ..append(new html.SelectElement()
          ..className = 'form-control input-sm'
          ..append(new html.OptionElement(data: 'in', value: 'in'))
          ..append(new html.OptionElement(data: 'out', value: 'out'))))
      ..append(new html.LIElement()
        ..append(new html.SpanElement()..text = 'when'))
      ..append(new html.LIElement()
        ..append(this.output.select(this.prevConn)))
      ..append(new html.LIElement()
        ..append(new html.SelectElement()
          ..className = 'form-control input-sm'
          ..append(new html.OptionElement(data: 'equals', value: 'equals'))
          ..append(new html.OptionElement(data: 'not equals', value: 'not equals'))
          ..append(new html.OptionElement(data: 'contains', value: 'contains'))))
      ..append(new html.LIElement()
        ..append(new html.InputElement(type: 'text')..className = 'form-control input-sm'))
    );

    count += 1;
    parameter.append(conditionDiv);
    parameter.append(configDiv);
    this.rulesDiv.append(parameter);
  }
}

class SortDetailsUI extends RuleDetailsUI {

  static int count = 1;

  SortDetailsUI(String id, String type, Map<String, bool> prevConn, Map<String, bool> nextConn) : super(id, type, prevConn, nextConn) {
    this.output = new SortOutputSpecification(this, this.id);
    this.view.append(this.output.view);
  }

  void initialize() {
    super.initialize();
    this.addElement('size', 'number', 'Window size', this.elements, features: {'min': '1', 'max': '100', 'value': '1'});

    // Ugly Hack to move rules after size parameter
    this.parametersView.append(this.rulesDiv);
  }

  void _addRule(html.MouseEvent e) {
    if (this.prevConn.length < 1) {
      log.warning('Please first make sure there is an input flow to this operator.');
      return;
    }

    html.DivElement parameter = new html.DivElement()
    ..className = 'row rule'
    ..id = '${this.id}-rule-${count}';

    html.DivElement conditionDiv = new html.DivElement()
    ..className = 'col-sm-3'
    ..append(new html.ButtonElement()
    ..text = '-'
    ..className = 'btn btn-danger btn-xs'
    ..onClick.listen((e) => _deleteRule(e, parameter.id)))
    ..append(new html.LabelElement()
    ..text = 'Sort using'
    ..className = 'text-muted');

    html.DivElement configDiv = new html.DivElement()
    ..className = 'col-sm-9'
    ..append(new html.UListElement()
      ..className = 'list-inline'
      ..append(new html.LIElement()
        ..append(this.output.select(this.prevConn)))
      ..append(new html.LIElement()
        ..append(new html.SpanElement()..text = 'in'))
      ..append(new html.LIElement()
        ..append(new html.SelectElement()
        ..className = 'form-control input-sm'
        ..append(new html.OptionElement(data: 'ascending', value: 'ascending'))
        ..append(new html.OptionElement(data: 'descending', value: 'descending'))))
      ..append(new html.LIElement()
        ..append(new html.SpanElement()..text = 'order'))
    );

    count += 1;
    parameter.append(conditionDiv);
    parameter.append(configDiv);
    this.rulesDiv.append(parameter);
  }
}

class SplitDetailsUI extends RuleDetailsUI {

  static int count = 1;

  SplitDetailsUI(String id, String type, Map<String, bool> prevConn, Map<String, bool> nextConn) : super(id, type, prevConn, nextConn) {
    this.output = new SplitOutputSpecification(this, this.id);
    this.view.append(this.output.view);
  }

  html.SelectElement outputSelectElement() {
    html.SelectElement selectElement = new html.SelectElement();
    selectElement.className = 'output-flows form-control input-sm';
    this.nextConn.forEach((identifier, connected) => selectElement.append(new html.OptionElement(data: identifier, value: identifier)));
    return selectElement;
  }

  void _addRule(html.MouseEvent e) {
    if (this.nextConn.length < 1) {
      log.warning('Please first make sure there is an output flow from this operator.');
      return;
    }

    if (this.prevConn.length < 1) {
      log.warning('Please first make sure there is an input flow to this operator.');
      return;
    }

    html.DivElement parameter = new html.DivElement()
    ..className = 'row rule'
    ..id = '${this.id}-rule-${count}';

    html.DivElement conditionDiv = new html.DivElement()
    ..className = 'col-sm-3'
    ..append(new html.UListElement()
      ..className = 'list-inline'
      ..append(new html.LIElement()
        ..append(new html.ButtonElement()
        ..text = '-'
        ..className = 'btn btn-danger btn-xs'
        ..onClick.listen((e) => _deleteRule(e, parameter.id))))
      ..append(new html.LIElement()
        ..append(new html.SpanElement()..text = 'Send to')));

    html.DivElement configDiv = new html.DivElement()
    ..className = 'col-sm-9'
    ..append(new html.UListElement()
      ..className = 'list-inline'
      ..append(new html.LIElement()
        ..append(this.outputSelectElement()))
      ..append(new html.LIElement()
        ..append(new html.SpanElement()..text = 'when'))
      ..append(new html.LIElement()
        ..append(this.output.select(this.prevConn)))
      ..append(new html.LIElement()
        ..append(new html.SelectElement()
        ..className = 'form-control input-sm'
        ..append(new html.OptionElement(data: 'equals', value: 'equals'))
        ..append(new html.OptionElement(data: 'not equals', value: 'not equals'))
        ..append(new html.OptionElement(data: 'contains', value: 'contains'))))
      ..append(new html.LIElement()
        ..append(new html.InputElement(type: 'text')..className = 'form-control input-sm'))
    );

    count += 1;
    parameter.append(conditionDiv);
    parameter.append(configDiv);
    this.rulesDiv.append(parameter);
  }
}