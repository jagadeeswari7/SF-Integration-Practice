public with sharing class SpoonacularController {

    private static final String SPOONACULAR_API = 'https://api.spoonacular.com';
    private static final String API_KEY = '00650e8dc38b419fa0c6fcabc036be1f';

    public static String getRandomRecipe() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(SPOONACULAR_API+'/recipes/random?apiKey='+API_KEY);
        HttpResponse response = http.send(request);

        if(response.getStatusCode() == 200) {
            System.debug('response::'+response.getBody());
            return response.getBody();
        }
        return null;
    }

    public static String getRecipeInfoById(String recipeId) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(SPOONACULAR_API+'/recipes/'+recipeId+'/information?apiKey='+API_KEY);
        HttpResponse response = http.send(request);

        if(response.getStatusCode() == 200) {
            System.debug('response::'+response.getBody());
            return response.getBody();
        }
        return null;
    }

    public static String getRecipeByIngredients(String ingredients) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(SPOONACULAR_API+'/recipes/findByIngredients?apiKey='+API_KEY+'&ingredients='+ingredients);
        HttpResponse response = http.send(request);

        if(response.getStatusCode() == 200) {
            System.debug('response::'+response.getBody());
            return response.getBody();
        }
        return null;
    }
}