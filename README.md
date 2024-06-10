# TIFF TO PDF Rails

A Rest API server that expects an array of tiff file names, base path(optional) and form name(optional) and returns the combined pdf of all the tiff files.

## Run Server inside Container

Go to the project directory

```bash
  cd tiff_to_pdf
```

Build docker image

```bash
  docker build -t tiff_to_pdf .
```

Start the container using generated image

```bash
  docker run -p 3000:3000 tiff_to_pdf
```

Make POST request to the endpoint with required payload
`http://localhost:3000/pdf/convert`

Payload Example:

```
{
  form_name: "example form",   <-- Optional
  files: [
    "file1.tiff",
    "file2.tiff",
    "file3.tiff"
  ],
  base_path: "https://base_path.com"   <-- Optional
}
```

## Running Tests

To run tests, run the following command

```bash
  rspec spec/services/tiff_pdf.rb
```
