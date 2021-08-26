document.addEventListener("turbolinks:load", () => {
    $("#issue_token_type").on('change',function(){
        console.log($(this).val())
        if($(this).val() === "195"){
            $("#amount_input").prop("disabled", true);
        }else{
            $("#amount_input").prop("disabled", false);
        }
    });
});