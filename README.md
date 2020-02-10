# CrossGuard at HackKU2020
 
## Inspiration
<p>We were inspired to create the CrossGuard when we saw a blind walking group in downtown Lincoln, Nebraska. They walk nearly every day for about an hour and they require a guide to transverse around Lincoln due to the traffic lights in Lincoln that change automatically instead of by a simple button press; they also do not have an audio indication of light changes. This requires each of the members in the blind group to have a guide whenever they want to travel somewhere. As a result, this restricts their opportunities to freely move around the city. This inspired us to create CrossGuard, an application designed to help remove these restrictions.</p>

## What it does
<p>This cross-platform mobile application aids disabled individuals, more specifically the blind, to navigate the busy streets on foot. Upon opening CrossGuard, the application prompts the user to state their destination. After confirming the destination with the user, CrossGuard outlines a route from their current location to their destination using Google Maps. CrossGuard then gives the user a summary of the weather conditions so the user is prepared and can determine whether or not it is safe for them to travel in the conditions. Then the application switches from the map to the user’s camera. As the user travels along the route, CrossGuard warns the user of upcoming intersections and alerts them when it is safe to proceed. Until the user reaches their destination, CrossGuard will continue to update them on directions and distances. Once the user has safely reached their destination, CrossGuard notifies them with a message saying “You have arrived”. </p>

## How we built it
* To create the application we used Flutter (a cross-platform application development framework) and Dart because we wanted the application to be available to all users.
* To implement the map feature, we used the Google Cloud Platform, Google Cloud Places API, Google Cloud Directions API, and Google Cloud API.
* To achieve the real-time video assistant, we used the Google Vision API.
* To translate the user’s speech into the text, we used the Flutter package speech_to_text.
* To translate text into speech, we used the Flutter package flutter_tts.
* To create the logo and other graphics, we used Adobe Illustrator and Adobe Photoshop.
* To efficiently progress through this project, we were determined to use GitHub to collaborate on this project. 

## Challenges we ran into
* Without previous experience, we had trouble utilizing different packages and APIs.
* While planning this project, we knew we wanted to use GitHub, a version control system we had all used before, to efficiently separate and manage our codebase. To further encourage the separation of tasks, we decided to utilize branches. We had only used branches once before, so we ran into plenty of challenges such as merge conflict and losing commits in other branches.
* Another challenge we had to overcome was to maintain consistent communication throughout an agile environment with a short time frame.
* There were times when we found it difficult to understand Flutter’s documentation due to its lack of history. 

## Accomplishments that we're proud of
* We are proud of how we were able to merge our work together. We were able to combine our ideas and research to create the best design possible, and we were able to combine the different parts of our implementation (user interface, backend, etc) cohesively into one final product.
* This was our first time creating a cross-platform mobile application that runs on IOS and Andriod. 

## What we learned
* We learned how to create a cross-platform Android and IOS app from scratch.
* We learned how to implement different types of APIs.
* We learned how to implement different packages.
* We learned how to implement multiple APIs and packages on the same project and have them work together.
* We learned how to use cutting edge technologies like Flutter. 
* We learned how to utilize asynchronous functions in a real-world project. 

## What's next for CrossGuard
* Cross Guard is looking to improve the weather warnings in particular with regards to the accuracy of whether or not there is ice possible, checking the evaporation so the user can determine if they want to delay their trip to avoid puddles, and using minute by minute data to be better predict what the conditions will be during your walk.
* To prove more accurate weather information, we would love to apply minute by minute data. 
* We are planning to train a model on our own to more accurately recognize traffic lights, whether or not you can cross, check for obstructions in the road, recognize tripping hazards such as potholes, and even warn of cars going at high speeds similar to a speed gun.
* Along with weather updates, we would like to also incorporate evaporation to help our users consider whether they want to wait for precipitation on the ground to dry in order to avoid puddles and more.
* We are planning on communicating with a local home for the blind so we can test our application and expand upon it to better suit their needs. 

