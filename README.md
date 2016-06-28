# Clarifai iOS

`v0.1.0` - An iOS client for interacting with the [Clarifai API](https://developer.clarifai.com/), written in Swift.

## Setup

**Note:** Clarifai-iOS uses [Alamofire](https://github.com/Alamofire/Alamofire). Please ensure it is available in your project.

Right now this library is drop-in (it's not yet available via Carthage or CocoaPods, but if [you're bored](https://github.com/jodyheavener/Clarifai-iOS/compare)...), so copy [Clarifai.swift](https://github.com/jodyheavener/Clarifai-iOS/blob/master/Clarifai.swift) over to your project and you're good to go.

From there, grab your Clarifai [API credentials](https://developer.clarifai.com/account/applications/) and instantiate the class:

```
client = Clarifai(clientID: "", clientSecret: "")
```

## Usage

### Recognition

Use Clarifai's core recognition service to identify Tags or Colors within an image.

```
client.recognize(type: Clarifai.RecognitionType, image: Array<UIImage> | url: Array<String>, model: Clarifai.TagModel, completion: (Clarifai.Response?, NSError?) -> Void)
```

**Options**

**`type`** | `Clarifai.RecognitionType ` (`enum`)

Default: `.Tag`

* `.Tag` - The [tag type](https://developer.clarifai.com/guide/tag#tag) is used to tag the contents of your images. Data is input into our system, processed with our deep learning platform and a list of tags is returned.
* `.Color` (beta) - The [color type](https://developer.clarifai.com/guide/color#color) is used to retrieve the dominant colors present in your images. Color values are returned in the hex format. A density value is also returned to let you know how much of the color is present. In addition, colors are also mapped to their closest W3C counterparts.

**`image`** | `Array<UIImage>` _or_ **`url`** | `Array<String>`

If only one of a given type is present in the array, the standard endpoints will be used. If multiple of a given type are a present, the endpoint changes to `/multiop` with a parameter of `op=tag|color`. Note: Color is not currently supported by the multi-op endpoint.

When using images, they are intentionally reduced in size and quality to use less data when uploading to Clarifai's servers. Generally this shouldn't affect the overall processing of an image, but feel free to tweak as needed. When using URLs, the strings are not validated so it's up to you to make sure proper image URLs are being passed in.

**`model`** | `Clarifai.TagModel` (`enum`)

Default: `.General`

* `.General` - The [General model](https://developer.clarifai.com/guide/tag#general) contains a wide range of tags across many different topics. In most cases, tags returned from the general model will sufficiently recognize what's inside your image.
* `.NSFW` - The [Not Safe For Work model](https://developer.clarifai.com/guide/tag#nsfw) analyzes images and returns probability scores on the likelihood that the image contains pornography.
* `.Weddings` - The [Wedding model](https://developer.clarifai.com/guide/tag#weddings) 'knows' all about weddings including brides, grooms, dresses, flowers, etc.
* `.Travel` - The [Travel model](https://developer.clarifai.com/guide/tag#travel) analyzes images and videos and returns probability scores on the likelihood that the image or video contains a recognized travel related category.
* `.Food` (beta) - The [Food model](https://developer.clarifai.com/guide/tag#food) analyzes images and videos and returns probability scores on the likelihood that the image or video contains a recognized food ingredient and dish.

Note: This option is only applicable to the Tag recognition type. It will be ignored when the Color type is used.

**`completion`** | `(Clarifai.Response?, NSError?) -> Void`

Only one object (`Clarifai.Response` or `NSError`) will be `nil`, so if an error is not present the response is guaranteed to be present.

**Responses**

The recognition method can return one or many results with tags or colors. Below are breakdowns of each object you'll find in a response.

**`Clarifai.Response`** | `NSObject`

The response carrying the result(s) of your request, as well as request status.

* `statusCode` | `String`
* `statusMessage` | `String`
* `recognitionType` | `Clarifai.RecognitionType` (`enum`)
* `results` | `Array<Clarifai.Result>` (`NSObject`)

**`Clarifai.Result`** | `NSObject`

A set of results from a given recognition type.

* `recognitionType` | `Clarifai.RecognitionType` (`enum`)
* `docId` | `String`
* `tags` | `Array<RecognitionTag>?` (`NSObject`)
* `colors` | `Array<RecognitionColor>?` (`NSObject`)

Note: the request's recognition type guarantees one of `tags` or `colors` will be present, and the other will not be present.

**`Clarifai.RecognitionTag`** | `NSObject`

A single tag returned from a recognition request.

* `classLabel` | `String`
* `probability` | `Float`
* `conceptId` | `String`

**`Clarifai.RecognitionColor`** | `NSObject`

A single color returned from a recognition request.

* `density` | `Float`
* `hex` | `String`
* `w3c` `Dictionary<String, String>`
  * `hex` | String
  * `name` | String
* `toColor()` | `UIColor` | Returns the color as a UIColor object

## Roadmap

- [x] Add support for Tag endpoint
- [x] Add support for Color endpoint
- [ ] Add support for Feedback endpoint
- [ ] Add support for Info endpoint
- [ ] Add support for Languages endpoint
- [ ] Add support for Usage endpoint
- [ ] Add method to `Clarifai.Result` that restricts tags/colors to certain results, like in the [Javascript client](https://github.com/Clarifai/clarifai-javascript#get-tags-for-an-image-via-url-and-restrict-the-tags-returned)

## Example app

There is a very rudimentary app available in the `example` directory. To get that up and running you'll need to have [Carthage](https://github.com/Carthage/Carthage) installed, and then do the following:

* Clone this entire repo
* `cd example`
* `carthage update --platform iOS`
* Fill in your Clarifai credentials (`clarifaiID ` and `clarifaiSecret `) in [example/Clarifai/MainViewController.swift](https://github.com/jodyheavener/Clarifai-iOS/blob/master/example/Clarifai/MainViewController.swift)
* Run the project in your iOS simulator or device

## License

This repository is released under the Apache License. See LICENSE for details.

## Contributing

If you find a bug or want to improve this library, just submit a pull request. Take care to maintain existing code style. Thanks!
