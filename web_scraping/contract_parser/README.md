# Contract Parser

This project contains a script for parsing information of collective labor contracts (CCT) in Mexico from official website URL's. 
The extracted data is saved to Excel tables. The script uses Selenium for web scraping and BeautifulSoup for parsing the HTML content.

## Project Structure

```plaintext
contract_parser/
├── config.json
├── contract_parser.py
├── README.md
├── requirements.txt
└── excel_tables/
    └── [output_file].xlsx
```

## Setup

### Prerequisites

- Python 3.6+
- Google Chrome

### Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/SilvioMJZ/SilvioMJZ_DataSciPortfolio.git
   cd SilvioMJZ_DataSciPortfolio/web_scraping/contract_parser
   ```
2. **Install the required Python packages:**
   
  ```bash
  pip install -r requirements.txt
  ```

3. **Configure ChromeDriver:**

The script uses webdriver-manager to handle the ChromeDriver installation, so you don't need to manually download and place ChromeDriver.

4. **Set up the configuration file:**

Edit the config.json file to specify the URLs to scrape and the output file paths.

### Run the script

```bash
python contract_parser.py
```

The script will save the extracted data to the specified Excel files in the output_files directory. 

## Project Details

### contract_parser.py

**ContractParser Class:** Handles the web scraping, data extraction, and saving to Excel.

- **__init__(self, url, output_file):** Initializes the parser with the URL to scrape and the output file path.
- **setup_driver(self):** Sets up the Chrome WebDriver with specified options.
- **close_modal(self):** Closes any modal pop-ups that appear on the webpage.
- **parse_table(self):** Parses the table on the webpage and extracts the data.
- **click_next(self):** Clicks the 'Next' button to navigate to the next page of the table.
- **parse(self):** Parses the entire table across all pages and saves the data to an Excel file.
- **save_to_excel(self):** Saves the extracted data to an Excel file.
- **load_config(config_path):** Loads the configuration from a JSON file.

### config.json

Specifies the URLs to scrape and the output file paths. You can add multiple URL-output file pairs.

### requirements.txt

Lists the required Python packages for the project:

```plaintext
pandas
selenium
beautifulsoup4
webdriver-manager
```

### License

This project is licensed under the MIT License. See the LICENSE file for details.


