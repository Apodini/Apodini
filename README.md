## How to use this repository
### Template
When creating a new repository make sure to select this repository as a repository template. ![](https://github.com/Apodini/Template-Repository/raw/develop/Images/RepositoryTemplate.png)

### GitHub Actions
This repository contains several workflows which require you to provide a GitHub Secret. Secrets are encrypted environment variables that you create in a repository for use with GitHub Actions.

#### 1. Create a personal access token
- Go to your token settings in GitHub (click on `Settings` in the user drop-down menu, then `Developer` settings in the sidebar, then click on `Personal access tokens`)
- Then click the `Generate token` button.
- Make sure to copy the access token

![](https://github.com/Apodini/Template-Repository/raw/develop/Images/AccessToken.png)

#### 2. Create a secret
Next, you’ll need to add a new secret to your repository.

- Open the settings for your repository and click `Secrets` in the sidebar
- Click `Add a new secret` and set the name to `ACCESS_TOKEN`
- Paste the copied personal access token into  `Value`
- Click `Add secret`

![](https://github.com/Apodini/Template-Repository/raw/release/Images/Secret.png)

### ⬆️ Remove everything up to here ⬆️

# Project Name

## Requirements

## Installation/Setup/Integration

## Usage

## Contributing
Contributions to this projects are welcome. Please make sure to read the [contribution guidelines](https://github.com/Apodini/.github/blob/release/CONTRIBUTING.md) first.

## License
This project is licensed under the MIT License. See [License](https://github.com/Apodini/Template-Repository/blob/release/LICENSE) for more information.
