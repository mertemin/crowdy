part of crowdy;

Map<String, List<String>> validationMessages = new Map<String, List<String>>();

const VALIDATION_ERROR = 'ERROR';
const VALIDATION_FAILURE = 'FAILED';
const VALIDATION_RESULT = 'RESULT';
const VALIDATION_SUCCESS = 'SUCCEED';
const VALIDATION_WARNING = 'WARNING';

Validation validation = new Validation();

class Validation {

  Map<String, Map> appDetails = new Map<String, Map>();

  Validation() {
    validationMessages[VALIDATION_ERROR] = new List<String>();
    validationMessages[VALIDATION_WARNING] = new List<String>();
  }

  void clear() {
    validationMessages[VALIDATION_ERROR].clear();
    validationMessages[VALIDATION_WARNING].clear();
  }

  void start() {
    this.clear();

    this.validate();
    bool valid = validationMessages[VALIDATION_ERROR].length == 0;
    if (valid){
      log.info("Validation is succeeded.");
    }
    else {
      log.warning("Validation failed.");
    }

    html.DListElement messageList = new html.DListElement()..className = "dl-horizontal";
    validationMessages.forEach(
        (String key, List<String> messages) => messages.forEach(
            (String message) => messageList.appendHtml("<dt>${key}</dt><dd>${message}</dd>")));
    appendToUtilityModalBody(messageList);

    appendToUtilityModalBody(new html.DListElement()..className = "dl-horizontal"
        ..appendHtml("<dt>${VALIDATION_RESULT}</dt><dd>${valid ? VALIDATION_SUCCESS : VALIDATION_FAILURE}</dd>"));

    if (valid) {
      for (String operatorId in operators.keys) {
        appDetails[operatorId] = operators[operatorId].getDetails();
      }

      appendToUtilityModalBody(new html.DivElement()
            ..className = 'row'
            ..append(new html.DivElement()..className = 'col-sm-12'
              ..append(new html.ParagraphElement()..id = 'result')));

      appendToUtilityModalFooter(new html.ButtonElement()..className = 'btn btn-default'
          ..text = 'Submit'..onClick.listen((e) => submitApplication(appDetails)));
    }

    showUtilityModal('Validation Result');

    print(appDetails);
  }

  void validate() {
    // Check if there are any operator
    if (operators.length == 0) {
      this.error("No operator added. Nothing to validate.");
      return;
    }

    // Overall check
    int sourceCount = 0;
    int sinkCount = 0;
    bool operatorWithNoConnection = false;
    appDetails.clear();
    for (String operatorId in operators.keys) {
      operators[operatorId].validate();
      sourceCount += (operators[operatorId].type.contains('source')) ? 1 : 0;
      sinkCount += (operators[operatorId].type.contains('sink')) ? 1 : 0;
      operatorWithNoConnection = operatorWithNoConnection || (operators[operatorId].next.length + operators[operatorId].prev.length == 0);
    }

    if (sourceCount == 0) {
      this.error("No source operator found.");
    }

    if (sinkCount == 0) {
      this.error("No sink operator found.");
    }

    if (operatorWithNoConnection) {
      this.warning("There are operators with no connection.");
    }
  }

  void warning(String message) {
    validationMessages[VALIDATION_WARNING].add(message);
  }

  void error(String message) {
    validationMessages[VALIDATION_ERROR].add(message);
  }

  int validateNumberInputElement(html.NumberInputElement input, int min, int max, bool required) {
    int result = 0;
    if (input.value.isEmpty) {
      result = required ? -1 : 0;
    }
    else {
      result = input.value is num ? 1 : -1;
    }
    return 0;
  }
}