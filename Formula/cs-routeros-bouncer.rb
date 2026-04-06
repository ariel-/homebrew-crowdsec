# typed: strict
# frozen_string_literal: true

class CsRouterosBouncer < Formula
  desc "CrowdSec bouncer for MikroTik RouterOS — manages address lists and firewall rules via the RouterOS API"
  homepage "https://jmrplens.github.io/cs-routeros-bouncer/"
  url "https://github.com/jmrplens/cs-routeros-bouncer/archive/refs/tags/v1.3.4.tar.gz"
  sha256 "dffc9b57e31df052766d126ec8da7fea49b81da1232e01d6973d06d149929e5d"
  license "MIT"

  depends_on "go" => :build

  ##
  # Builds and installs the cs-routeros-bouncer executable and ensures a default configuration is installed.
  #
  # The built binary has the formula version embedded via linker flags and is installed to bin/"cs-routeros-bouncer".
  # Creates the etc/cs-routeros-bouncer directory and copies config/cs-routeros-bouncer.yaml into it only if the destination file does not already exist.
  def install
    commit = "35f70c8"
    build_date = Time.now.utc.strftime("%FT%TZ")

    ldflags = %W[
      -s
      -w
      -X github.com/jmrplens/cs-routeros-bouncer/internal/config.Version=v#{version}
      -X github.com/jmrplens/cs-routeros-bouncer/internal/config.Commit=#{commit}
      -X github.com/jmrplens/cs-routeros-bouncer/internal/config.BuildDate=#{build_date}
      -X github.com/crowdsecurity/go-cs-lib/version.Version=v#{version}
    ].join(" ")

    system "go", "build", *std_go_args(output: bin/"cs-routeros-bouncer", ldflags: ldflags), "./cmd/cs-routeros-bouncer"

    config_dir = etc/"cs-routeros-bouncer"
    config_dst = config_dir/"cs-routeros-bouncer.yaml"
    config_dir.mkpath
    cp "config/cs-routeros-bouncer.yaml", config_dst unless config_dst.exist?
  end

  def caveats
    <<~EOS
      Configuration file installed to:
        #{etc}/cs-routeros-bouncer/cs-routeros-bouncer.yaml

      Please edit this file to set up your RouterOS connection and bouncer settings.
    EOS
  end

  test do
    output = shell_output("#{bin}/cs-routeros-bouncer --version")
    assert_match version.to_s, output
  end
end
