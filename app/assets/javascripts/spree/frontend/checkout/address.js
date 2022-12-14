Spree.ready(function($) {
  if ($("#checkout_form_address").is("*")) {
    // Hidden by default to support browsers with javascript disabled
    $(".js-address-fields").show();

    var getCountryId = function(region) {
      return $("#" + region + "country select").val();
    };

    var statesByCountry = {};

    var updateState = function(region) {
      var countryId = getCountryId(region);
      if (countryId != null) {
        if (statesByCountry[countryId] == null) {
          $.get(
            Spree.routes.states_search,
            {
              country_id: countryId
            },
            function(data) {
              statesByCountry[countryId] = {
                states: data.states,
                states_required: data.states_required
              };
              fillStates(region);
            }
          );
        } else {
          fillStates(region);
        }
      }
    };

    var fillStates = function(region) {
      var countryId = getCountryId(region);
      var data = statesByCountry[countryId];
      if (data == null) {
        return;
      }
      var statesRequired = data.states_required;
      var states = data.states;
      var statePara = $("#" + region + "state");
      var stateSelect = statePara.find("select");
      var stateInput = statePara.find("input");
      if (states.length > 0) {
        var selected = parseInt(stateSelect.val());
        stateSelect.html("");
        var statesWithBlank = [
          {
            name: "",
            id: ""
          }
        ].concat(states);
        $.each(statesWithBlank, function(idx, state) {
          var opt;
          opt = $(document.createElement("option"))
            .attr("value", state.id)
            .html(state.name);
          if (selected === state.id) {
            opt.prop("selected", true);
          }
          stateSelect.append(opt);
        });
        stateSelect.prop("disabled", false).show();
        stateInput.hide().prop("disabled", true);
        statePara.show();
        if (statesRequired) {
          stateSelect.addClass("required");
          statePara.addClass("field-required");
        } else {
          stateSelect.removeClass("required");
          statePara.removeClass("field-required");
        }
        stateInput.removeClass("required");
      } else {
        stateSelect.hide().prop("disabled", true);
        stateInput.show();
        if (statesRequired) {
          statePara.addClass("field-required");
          stateInput.addClass("required");
        } else {
          stateInput.val("");
          statePara.removeClass("field-required");
          stateInput.removeClass("required");
        }
        statePara.toggle(!!statesRequired);
        stateInput.prop("disabled", !statesRequired);
        stateSelect.removeClass("required");
      }
    };

    $("#bcountry select").change(function() {
      updateState("b");
    });

    $("#scountry select").change(function() {
      updateState("s");
    });

    updateState("b");

    var order_use_billing = $("input#order_use_billing");
    order_use_billing.change(function() {
      update_shipping_form_state(order_use_billing);
    });

    var update_shipping_form_state = function(order_use_billing) {
      if (order_use_billing.is(":checked")) {
        $("#shipping .inner").hide();
        $("#shipping .inner input, #shipping .inner select").prop(
          "disabled",
          true
        );
      } else {
        $("#shipping .inner").show();
        $("#shipping .inner input, #shipping .inner select").prop(
          "disabled",
          false
        );
        updateState("s");
      }
    };

    update_shipping_form_state(order_use_billing);
  }
});



$(document).ready(function(){
  $('#same_billing').change(function(){
    if ($('#same_billing')[0].checked == true)
      $('#billing').slideUp();
    else
      $('#billing').slideDown();
  });

  $('.payment-method').not('.btn').on('click', function() {
    $('.payment-method').css("border", "none")
    $(this).css("border", "2px solid black")
  });

  $('.payment-method').click(function() {
    document.forms["checkout_form_payment"]["payment_method"].value = $(this).attr('data');
  })

})

function shippingInfo() {
  $('.go-home').removeClass('d-none-m');
  $('.checkout-param-group').not('#shipping-box').addClass('d-none-m');
  $('#shippingBody').removeClass('d-none-m');
  $('.checkout-status').attr('data-id', 'shipping-box');
  $('.box-title').hide();
  $('#shippingInfo').removeClass('d-flex');
  $('#shippingInfo').addClass('d-none-m');
  $('#billing').removeClass('d-none-m');
  $('#breadcrumbLabel').text('Shipping Information');
}

function paymentInfo() {
  $('.go-home').removeClass('d-none-m');
  $('.box-title').hide();
  $('.checkout-param-group').not('#payment-box').addClass('d-none-m');
  $('#paymentMBody').removeClass('d-none-m');
  $('#paymentInfo').addClass('d-none-m');
  $('.checkout-status').attr('data-id', 'payment-box');
  $('.dropdown-divider').removeClass('d-none-m');
  $('#card_info').addClass('d-none-m');
  $('#breadcrumbLabel').text('Payment Information');
  $('#payment').removeClass('mt-4');
}

function goCheckoutHome() {
  cur_box = $('.checkout-status').attr('data-id');
  if (cur_box == 'shipping-box')
    goHomeFromShipping();
  else if (cur_box == 'payment-box')
    goHomeFromPayment();
  $('.checkout-status').attr('data-id', '');
  $('#breadcrumbLabel').text('Order Confirmation')
}

function goHomeFromShipping() {
  var str = $('#full_name').val() ? $('#full_name').val() + '\n' : '';
  str += $('#street').val() ? $('#street').val() + '\n' : '';
  str += $('#apartment').val() ? $('#apartment').val() + '\n' : '';
  str += $('#city').val() ? $('#city').val() + '\n' : '';
  if(str !== '')
    $('.shipping-info-content').text(str);
  $('.checkout-param-group').not('#shipping-box').removeClass('d-none-m');
  $('.go-home').addClass('d-none-m');
  $('#shippingBody').addClass('d-none-m');
  $('#billing').addClass('d-none-m');
  $('#shippingInfo').addClass('d-flex');
  $('#shippingInfo').removeClass('d-none-m');
  $('.box-title').show();
}

function goHomeFromPayment() {
  $('.go-home').addClass('d-none-m');
  $('.box-title').show();
  $('.checkout-param-group').not('#payment-box').removeClass('d-none-m');
  $('#paymentMBody').addClass('d-none-m');
  $('#paymentInfo').removeClass('d-none-m');
  $('.checkout-status').attr('data-id', '');
  $('.dropdown-divider').addClass('d-none-m');
  $('#card_info').removeClass('d-none-m');
  $('#breadcrumbLabel').text('Order Confirmation');
  $('#payment').addClass('mt-4');
}

function payByCredit() {
  $('#card_info').removeClass('d-none-m')
}