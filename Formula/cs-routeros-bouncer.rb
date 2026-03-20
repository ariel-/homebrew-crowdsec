# typed: strict
# frozen_string_literal: true

class CsRouterosBouncer < Formula
  desc "CrowdSec bouncer for MikroTik RouterOS — manages address lists and firewall rules via the RouterOS API"
  homepage "https://jmrplens.github.io/cs-routeros-bouncer/"
  url "https://github.com/jmrplens/cs-routeros-bouncer/archive/refs/tags/v1.3.3.tar.gz"
  sha256 "0c9e9291fae3e4e7b810648971ed00587cda93ace6189ced19a5a897fcf24355"
  license "MIT"

  depends_on "go" => :build

  ##
  # Builds cs-routeros-bouncer with linker flags that embed the formula version, installs the resulting binary into bin, and ensures a default configuration file exists under etc/cs-routeros-bouncer.
  # The build strips debug symbols and sets `internal/config.Version` to the formula `version`.
  # Creates the configuration directory `etc/"cs-routeros-bouncer"` and copies `config/cs-routeros-bouncer.yaml` there only if the destination file is not already present.
  def install
    ldflags = %W[
      -s
      -w
      -X github.com/jmrplens/cs-routeros-bouncer/internal/config.Version=v#{version}
    ].join(" ")

    system "go", "build", *std_go_args(output: bin/"cs-routeros-bouncer", ldflags: ldflags), "./cmd/cs-routeros-bouncer"

    config_dir = etc/"cs-routeros-bouncer"
    config_dst = config_dir/"cs-routeros-bouncer.yaml"
    config_dir.mkpath
    cp "config/cs-routeros-bouncer.yaml", config_dst unless config_dst.exist?
  end

  test do
    system bin/"cs-routeros-bouncer", "--version"
  end
end
