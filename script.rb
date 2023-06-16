require 'js'
require 'csv'
require 'date'

def reformat_csv(text:)
  StringIO.open do |io|
    CSV(text, headers: true, skip_blanks: true) do |csv|
      csv.each do |row|
        case row['Date']
        when 'Today'
          date = Date.today
        when 'Yesterday'
          date = Date.today - 1
        else
          date = Date.parse(row['Date'])
        end

        io.puts([
          date.strftime('%d/%m/%Y'),
          row['Amount'].gsub(/,/, ''),
          row['Description'].gsub(/,/, '')
        ].join(','))
      end
    end
    io.rewind
    io.read
  end
end

def create_url(text:, filename:)
  escaped_text = text.gsub(/\n/, "\\\\n")

  JS.eval(%(
    return URL.createObjectURL(
      new File(['#{escaped_text}'], '#{filename}', { type: "text/csv" }))
    )
  )
end

document = JS.global[:document]
form = document.getElementById('upload')
form.addEventListener('submit') do |event|
  event.preventDefault
  input = document.getElementById('file')
  input_file = input['files'][0]
  input_file.text.call(:then) do |input_text|
    output_text = reformat_csv(text: input_text.to_s)
    basename = File.basename(input_file[:name].to_s, '.csv')
    output_filename = "#{basename}.freeagent.csv"
    url = create_url(text: output_text, filename: output_filename)
    download_button = document.getElementById('download')
    download_button[:href] = url
    download_button[:download] = output_filename
    download_button[:classList].remove('disabled')
  end
end
