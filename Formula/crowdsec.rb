# typed: strict
# frozen_string_literal: true

# This is a Homebrew formula for installing Crowdsec
class Crowdsec < Formula
  desc "Open-source and participative security solution"
  homepage "https://crowdsec.net"
  url "https://github.com/crowdsecurity/crowdsec/archive/refs/tags/v1.7.6.tar.gz"
  sha256 "1be0c4e7d3e437698203f6badac323b7e4d9c461716274df879ebb3ae054ca4e"

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(output: "crowdsec"), "./cmd/crowdsec"
    system "go", "build", *std_go_args(output: "cscli"), "./cmd/crowdsec-cli"

    # Install binaries
    bin.install "crowdsec"
    bin.install "cscli"

    # Install default configuration (Homebrew-friendly paths)
    lib_dir = var/"lib/crowdsec"
    usr_dir = lib/"crowdsec"
    data_dir = lib_dir/"data"
    config_dir = etc/"crowdsec"
    plugin_dir = usr_dir/"plugins"

    data_dir.mkpath
    (config_dir/"acquis.d").mkpath
    (config_dir/"hub").mkpath

    inreplace "config/config.yaml" do |s|
      s.gsub! "/etc/crowdsec/", "#{config_dir}/"
      s.gsub! "/var/lib/crowdsec/data/", "#{data_dir}/"
      s.gsub! "/var/log/", "#{var/"log"}/"
      s.gsub! "/usr/local/lib/crowdsec/plugins/", "#{plugin_dir}/"
    end

    %w[
      config.yaml
      dev.yaml
      user.yaml
      acquis.yaml
      profiles.yaml
      simulation.yaml
      console.yaml
      local_api_credentials.yaml
      online_api_credentials.yaml
    ].each do |cfg|
      dst = config_dir/cfg
      next if dst.exist?

      cp "config/#{cfg}", dst
      chmod 0600, dst if cfg.end_with?("_credentials.yaml")
    end

    # Data defaults
    detect_dst = data_dir/"detect.yaml"
    cp "config/detect.yaml", detect_dst unless detect_dst.exist?

    ENV["CROWDSEC_SETUP_DETECT_CONFIG"] = detect_dst

    system bin/"cscli", "hub", "update", "-c", "#{config_dir}/config.yaml"
    system bin/"cscli", "setup", "unattended", "-c", "#{config_dir}/config.yaml"

    # Patterns are safe to install, but don't overwrite user edits.
    cp_r "config/patterns", config_dir unless (config_dir/"patterns").exist?
  end

  def caveats
    <<~EOS
      CrowdSec configuration is installed into:

        #{etc}/crowdsec

      This formula does NOT run any setup wizard; you must edit the config and
      run CrowdSec manually. Example:

        crowdsec -c #{etc}/crowdsec/config.yaml

      To manage the hub (parsers, scenarios, bouncers):

        cscli -c #{etc}/crowdsec/config.yaml hub update

      The default installation does not register against LAPI, to do so, you can run:
        cscli -c #{etc}/crowdsec/config.yaml machines add --force "ID" -a -f "#{etc}/crowdsec/local_api_credentials.yaml"
        cscli -c #{etc}/crowdsec/config.yaml capi register
    EOS
  end

  test do
    system bin/"crowdsec", "--version"
  end
end
