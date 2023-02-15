#!/usr/bin/env ruby

# Remove packages and channels for a given distro if any
# from RMT mirrored data
class RemoveMirroredData
  def initialize(mirror_dir, num_packages, distro)
    check_distro(distro) unless distro.nil?
    check_num_packages(num_packages.to_i)
    @mirror_dir = mirror_dir
    @packages = []
    @num_packages = num_packages.to_i || 0
    @distro = distro
  end

  def remove_packages
    return if @num_packages.zero?

    find_packages
    @num_packages.times do
      puts @packages[rand(@packages.length)]
      # @packages[rand(@packages.length)]
    end
  end

  def find_packages
    repo_dirs = []

    Dir[@mirror_dir + '/**/*'].each do |f|
      next unless File.directory?(f)

      repo_dirs << File.expand_path(File.join(f, '..')) if File.basename(f) == 'repodata'
    end

    repo_dirs.each do |repo_dir|
      Dir[repo_dir + '/**/*'].each { |f| @packages << f if f =~ /rpm$/ }
    end
  end

  def remove_distro_channels
    # mirror process replace directory joining
    # mirror base dir (../public/repo) + local path of the repo
    # Dir[@mirror_dir + "/**/#{distro}"].each { |f| Dir.rmdir f }
    all_paths = Dir[
      File.join(@mirror_dir, "/**/#{@distro}"),
      File.join(@mirror_dir, "/**/#{backport_format}")
    ]
    if all_paths.empty?
      puts "No channels found for #{@distro}"
      return
    end

    all_paths.each { |f| puts f}
    # Dir[File.join(@mirror_dir, "/**/#{@distro}")].each { |f| puts f } # Dir.rmdir f }
  end

  private

  def backport_format
    # for example
    # from SLE/12-SP5/x86_64 to SLE-12-SP5_x86_65
    # from SLE/15/aarch64 to SLE-15_aarch64
    backport = @distro.split('/')
    return backport[0] + '-' + backport[1..backport.length].join('_')
  end

  def check_distro(distro)
    return if (distro.count('/') == 2 || distro.split('/').length == 3)

    raise 'Distribution must be formed as <product>/<version>/<arch>'
  end

  def check_num_packages(num_packages)
    # TODO: remove condition for number of packages
    raise 'Number of packages should be 250, 500 or 750' unless [250, 500, 750].include? num_packages
  end
end

mirror_dir = ARGV[0]
raise "#{mirror_dir} doesn't exist or isn't a directory" unless File.exist?(mirror_dir) and File.directory?(mirror_dir)

num_packages = ARGV[1]
distro = ARGV[2]
remove_mirorred_data = RemoveMirroredData.new(mirror_dir, num_packages, distro)

remove_mirorred_data.remove_packages
remove_mirorred_data.remove_distro_channels unless distro.nil?
