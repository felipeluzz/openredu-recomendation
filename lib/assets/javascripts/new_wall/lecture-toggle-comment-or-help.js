$(function() {
  $(document).on("click", ".lecture-wall-wrapper .button-comment", function() {
    var $button = $(this);
    var $action = $button.parent();
    var $wrapper = $button.closest(".lecture-wall-wrapper");
    var $actions = $wrapper.find(".lecture-wall-action");
    var $createStatus = $wrapper.find(".create-status");
    var $textArea = $createStatus.find("textarea");
    var $statusType = $createStatus.find('[name="status[type]"]');

    $actions.removeClass("open");
    $action.addClass("open");

    if (!$createStatus.data("open")) {
      $createStatus.slideDown(150, "swing");
      $createStatus.data("open", true);
    }

    $createStatus.removeClass("tab-right");
    $createStatus.addClass("tab-left");
    $textArea.attr("placeholder", "Comente nesta aula.");
    $statusType.val("Activity");
    $textArea.focus();
  });

  $(document).on("click", ".lecture-wall-wrapper .button-help", function() {
    var $button = $(this);
    var $action = $button.parent();
    var $wrapper = $button.closest(".lecture-wall-wrapper");
    var $actions = $wrapper.find(".lecture-wall-action");
    var $createStatus = $wrapper.find(".create-status");
    var $textArea = $createStatus.find("textarea");
    var $statusType = $createStatus.find('[name="status[type]"]');

    $actions.removeClass("open");
    $action.addClass("open");

    if (!$createStatus.data("open")) {
      $createStatus.slideDown(150, "swing");
      $createStatus.data("open", true);
    }

    $createStatus.removeClass("tab-left");
    $createStatus.addClass("tab-right");
    $textArea.attr("placeholder", "Peça ajuda nesta aula.");
    $statusType.val("Help");
    $textArea.focus();
  });

  // No cancelar, remove também a classe de aberto.
  $(document).on("click", ".lecture-wall-wrapper .cancel", function(e) {
    var $wrapper = $(this).closest(".lecture-wall-wrapper");
    var $actions = $wrapper.find(".lecture-wall-action");
    var $createStatus = $wrapper.find(".create-status");

    $actions.removeClass("open");
    $createStatus.slideUp(150, "swing").data("open", false);
  });

  //Botão de recomendações
  $(document).on("click", ".button-recomendation", function () {
    $(this).fadeOut();
    $("#first_recommendation").delay(400).fadeIn();
    $("#first_friend_recommendation").delay(400).fadeIn();
  });
  $(document).on("click", "#second_friend_button", function () {
    $("#first_friend_recommendation").fadeOut();
    $("#second_friend_recommendation").delay(400).fadeIn();
  });
  $(document).on("click", "#third_friend_button", function () {
    $("#second_friend_recommendation").fadeOut();
    $("#third_friend_recommendation").delay(400).fadeIn();
  });
  $(document).on("click", "#second_recommendation_button", function () {
    $("#first_recommendation").fadeOut();
    $("#second_recommendation").delay(400).fadeIn();
  });
  $(document).on("click", "#third_recommendation_button", function () {
    $("#second_recommendation").fadeOut();
    $("#third_recommendation").delay(400).fadeIn();
  });
});

