defmodule OpenapiParser.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/tomgeene/openapi_parser"

  def project do
    [
      app: :openapi_parser,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "OpenapiParser",
      source_url: @source_url
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:yaml_elixir, "~> 2.9"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    A comprehensive OpenAPI specification parser for Elixir. Supports OpenAPI 2.0 (Swagger),
    3.0, and 3.1 specifications in both JSON and YAML formats with full validation.
    """
  end

  defp package do
    [
      name: "openapi_parser",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      },
      maintainers: ["Tom Geene"]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md", "LICENSE"],
      source_ref: "v#{@version}",
      source_url: @source_url,
      formatters: ["html"],
      groups_for_modules: [
        Core: [
          OpenapiParser,
          OpenapiParser.Parser,
          OpenapiParser.Spec,
          OpenapiParser.Validation
        ],
        "OpenAPI V2 (Swagger 2.0)": [
          OpenapiParser.Spec.V2.Swagger,
          OpenapiParser.Spec.V2.Schema,
          OpenapiParser.Spec.V2.Parameter,
          OpenapiParser.Spec.V2.Response,
          OpenapiParser.Spec.V2.Operation,
          OpenapiParser.Spec.V2.PathItem
        ],
        "OpenAPI V3": [
          OpenapiParser.Spec.V3.OpenAPI,
          OpenapiParser.Spec.V3.Schema,
          OpenapiParser.Spec.V3.Parameter,
          OpenapiParser.Spec.V3.RequestBody,
          OpenapiParser.Spec.V3.Response,
          OpenapiParser.Spec.V3.Operation,
          OpenapiParser.Spec.V3.PathItem,
          OpenapiParser.Spec.V3.Components
        ],
        "Shared Spec Objects": [
          OpenapiParser.Spec.Info,
          OpenapiParser.Spec.Contact,
          OpenapiParser.Spec.Tag,
          OpenapiParser.Spec.ExternalDocumentation
        ]
      ]
    ]
  end
end
