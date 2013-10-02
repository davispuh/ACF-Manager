#!/usr/bin/env ruby
# encoding: UTF-8
require 'steam_codec'
require 'optparse'
require 'set'
require 'pathname'

os = Gem::Platform.local.os
$isWindows = (os == 'mingw32' or os == 'mingw64')

# Normalize path so that there's no double slashes
# and for Windows replace backslashes to forwardslashes
# @param path [String] path
# @return [String] normalized path
def normalizePath(path)
    path.gsub!('\\','/') if $isWindows
    path.gsub!(/\/\/+/,'/')
    path.chomp('/')
end

def fromLinuxRegistry(path)
    value = nil
    File.open(Dir.home+'/.steam/registry.vdf', 'r:UTF-8') do |file|
        registry = SteamCodec::VDF::loadFromFile(file)
        break unless registry and registry.Registry
        value = registry.Registry.get(path)
    end
    value
rescue StandardError => e
    $stderr.puts e.message
end

def getSteamPath
    platform = Gem::Platform.local
    case platform.os
    when 'mingw32', 'mingw64'
        require 'win32/registry'
        registryPath = 'SOFTWARE\Valve\Steam'
        registryPath = 'SOFTWARE\Wow6432Node\Valve\Steam' if platform.cpu == 'x64'
        begin
            Win32::Registry::HKEY_LOCAL_MACHINE.open(registryPath, Win32::Registry::KEY_READ) do |reg|
                return normalizePath(reg['InstallPath'].to_s)
            end
        rescue Win32::Registry::Error => e
            $stderr.puts e.message
        end
    when 'darwin'
        return Dir.home+'/Library/Application Support/Steam'
    else
        $stderr.puts "Uknown OS: #{platform.os}" if platform.os != 'linux'
        installPath = fromLinuxRegistry('Registry/HKLM/SOFTWARE/Valve/Steam/InstallPath')
        installPath = Dir.home+'/.local/share/Steam' unless installPath
        return normalizePath(installPath.to_s)
    end
end

def getOptions
    options = {
        :SteamPaths => [], :AppDirs => [], :Action => :export,
        :Fields => ['AppID', 'StateFlags', 'InstallDir', 'SizeOnDisk', 'BuildId', 'UserConfig.Name', 'UserConfig.Installed', 'UserConfig.AppInstallDir'],
        :Mode => :downloaded, :Format => :csv, :File => nil }
    parser = OptionParser.new do |opts|
        opts.banner = 'Usage: acf_manager.rb [options]'
        opts.on('-p', '--paths steam', Array, 'Paths to Steam directories') do |paths|
            paths.each do |path|
                options[:SteamPaths] << normalizePath(path)
            end
        end
        opts.on('-a','--apps paths', Array, 'Paths to SteamApps directories') do |paths|
            paths.each do |path|
                options[:AppDirs] << normalizePath(path)
            end
        end
        opts.on('-e','--execute ACTION', [:export, :list], 'Execute specified action (export, list)') do |action|
            options[:Action] = action
        end
        opts.on('-f','--fields fields', Array, 'Specify which fields to export') do |fields|
            options[:Fields] = fields
        end
        opts.on('-m','--mode MODE', [:downloaded, :installed, :unreferenced], "Mode for `list` (downloaded, installed,\n#{' '*37}unreferenced)") do |mode|
            options[:Mode] = mode
        end
        opts.on('-o','--output FORMAT', [:csv, :yml, :json, :xml, :vdf], 'Output format (csv, yml, json, xml, vdf)') do |format|
            options[:Format] = format
        end
        opts.on('-s','--save FILE', 'File where to save output') do |file|
            options[:File] = file
        end
        opts.on_tail('-h', '--help', 'Show this message') do
            puts opts
            return false
        end
    end
    begin
        parser.parse!
    rescue OptionParser::ParseError => e
        $stderr.puts e.message
        return false
    end
    return options
end

def rowToHash(header, rowData)
    hashRow = {}
    header.each_index do |i|
        headerName = header[i].split('.')
        headerCount = headerName.length
        current = hashRow
        headerName.each_index do |j|
            current[headerName[j]] = {} unless current[headerName[j]]
            if j == headerCount - 1
                current[headerName[j]] = rowData[i]
            else
                current = current[headerName[j]]
            end
        end
    end
    hashRow
end

def tableToArray(header, rows)
    data = []
    rows.each do |row|
        data << rowToHash(header, row)
    end
    data
end

def formatter(format, &block)
    header = []
    data = []
    yield(header, data)
    case format
    when :yml
        require 'yaml'
        return YAML.dump(tableToArray(header, data))
    when :json
        require 'json'
        return JSON.dump(tableToArray(header, data))
    when :xml
        require 'gyoku'
        xmlContent = '<?xml version="1.0" encoding="UTF-8"?>'
        xmlContent += "\n<result>\n"
        xmlContent += Gyoku::xml({ :entry => tableToArray(header, data)}, { :key_converter => :none, :builder => { :indent => 2} })
        return xmlContent+'</result>'
    when :vdf
        $stderr.puts "Sorry, format `#{format.to_s}` is not implemented yet."
    end
    require 'csv'
    CSV.generate({:encoding => 'UTF-8', :col_sep => ',', :force_quotes => false, :headers => true}) do |csv|
        csv << header
        data.each do |row|
            csv << row
        end
    end
end

def main
    options = getOptions
    return false unless options
    options[:SteamPaths] << getSteamPath if options[:SteamPaths].count == 0
    validSteamPaths = []
    options[:SteamPaths].each do |steamPath|
        if File.directory?(steamPath)
            validSteamPaths << steamPath
            options[:AppDirs] << steamPath+'/SteamApps'
            begin
                File.open(steamPath+'/config/config.vdf', 'r:UTF-8') do |file|
                    configData = SteamCodec::VDF::loadFromFile(file)
                    break unless configData
                    steamConfig = configData.get('InstallConfigStore/Software/Valve/Steam')
                    break unless steamConfig
                    steamFolders = steamConfig.asArray('BaseInstallFolder')
                    options[:SteamPaths] += steamFolders
                    steamFolders.each do |folder|
                        next unless File.directory?(folder)
                        path = normalizePath(folder)
                        validSteamPaths << path
                        options[:AppDirs] << path+'/SteamApps'
                    end
                end
            rescue StandardError => e
                $stderr.puts e.message
            end
        else
            $stderr.puts "Steam path #{steamPath} does\'t exist"
        end
    end

    options[:AppDirs] << '.' if Dir['appmanifest_*.acf'].count > 0

    if options[:AppDirs].count == 0
        $stderr.puts 'There\'s no SteamApps directory specified'
        return false
    end

    result = formatter(options[:Format]) do |header, data|
        if options[:Action] == :list
            case options[:Mode]
            when :downloaded
                header << 'AppID'
                header << 'UserConfig.Name'
                header << 'InstallDir'
                header << 'AppDir'
            when :installed
                header << 'AppID'
                header << 'UserConfig.Name'
                header << 'InstallDir'
                header << 'UserConfig.AppInstallDir'
            when :unreferenced
                header << 'InstallDir'
                header << 'AppPath'
            end
        else
            options[:Fields].each do |field|
                header << field
            end
        end
        options[:AppDirs].each do |appDir|
            if not File.directory?(appDir)
                $stderr.puts "#{appDir} Doesn't exist!"
                next
            end
            gameDirs = Set.new
            gameData = []
            Dir.glob(appDir+'/appmanifest_*.acf') do |filename|
                File.open(filename, 'r:UTF-8') do |file|
                    acf = SteamCodec::ACF::loadFromFile(file)
                    if acf
                        if options[:Action] == :list
                            case options[:Mode]
                            when :downloaded
                                gameData << [acf.AppID, acf.UserConfig.Name, acf.InstallDir, appDir]
                            when :installed
                                gameData << [acf.AppID, acf.UserConfig.Name, acf.InstallDir, normalizePath(acf.UserConfig.AppInstallDir)] if acf.UserConfig.Installed
                            when :unreferenced
                                if not acf.InstallDir.nil?
                                    gameDirs << normalizePath(acf.InstallDir)
                                else
                                    $stderr.puts "#{filename} : Invalid ACF! Doesn't have `installdir` key"
                                end
                            end
                        else
                            entry = []
                            header.each do |name|
                                entry << acf.get(name)
                            end
                            gameData << entry
                        end
                    else
                        $stderr.puts "#{filename} : Invalid ACF"
                    end
                end
            end
            if options[:Action] == :list and options[:Mode] == :unreferenced
                sorted = gameDirs.sort_by { |dir| dir.downcase }
                Pathname.glob(appDir+'/common/*/').each do |dir|
                    name = dir.basename.to_s
                    data << [name.to_s, dir.cleanpath.to_s]  unless sorted.include?(name)
                end
            else
                gameData.sort_by do |d|
                    if d.first.is_a?(Numeric)
                        d.first
                    else
                        d.first.to_s
                    end
                end.each do |entry|
                    data << entry
                end
            end

        end
    end

    if options[:File]
        extension = ''
        extension = '.' + options[:Format].to_s unless options[:File].include? '.'
        File.open(options[:File] + extension, 'w:UTF-8') do |file|
            file.write(result)
        end
    else
        puts result
    end
    true
end

main unless $spec
