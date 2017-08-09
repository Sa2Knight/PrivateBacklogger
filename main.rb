require 'backlog_kit'
require 'optparse'
require 'pp'
class PrivateBacklogger

  @@SPACE_ID          = "saknight"
  @@PROJECT_ID        = "38382"
  @@PROJECT_NAME      = "DEV"
  @@UNCOMPLETE_STATUS = [1, 2, 3]  # 未対応/処理中/処理済み
  @@COMPOLETE_STATUS  = 4          # 完了
  @@TASK_ISSUE_TYPE   = "172585"   # タスク
  @@DEV_CATEGORY      = "79173"    # 開発関係
  @@WORK_CATEGORY     = "79171"    # 仕事関係
  @@OTHER_CATEGORY    = "79172"    # その他タスク
  @@PRIORITY_ID       = 1          # 優先度 中
  @@RESOLUTION_ID     = 0          # 対応済み

  def initialize
    @backlog = BacklogKit::Client.new(space_id: @@SPACE_ID, api_key: ENV['PRIVATE_BACKLOG_API_KEY'])
  end

  # 未完了の課題を一覧
  def list
    params = {projectId: [@@PROJECT_ID], statusId: @@UNCOMPLETE_STATUS}
    issues = @backlog.get_issues(params).body
    issues.each do |i|
      puts "#{i.issueKey.delete('DEV-')}: #{i.summary}"
    end
  end

  # 課題名を取得
  def summary(issue_id)
    @backlog.get_issue("DEV-#{issue_id}").body.summary
  end

  # URLを表示
  def url(issue_id)
    puts "saknight.backlog.jp/view/DEV-#{issue_id}"
  end

  # 課題をクローズ
  def close(issue_id)
    summary = self.summary(issue_id)
    print "#{summary} をクローズします y/n "
    answer = gets.chomp
    if answer === 'y'
      params = {
        statusId:     @@COMPOLETE_STATUS,
        resolutionId: @@RESOLUTION_ID,
      }
      @backlog.update_issue("DEV-#{issue_id}", params)
      self.list
    end
  end

  # 開発関係の課題を作成
  def create_develop_issue(summary)
    create(summary, @@DEV_CATEGORY)
  end

  # 仕事関係の課題を作成
  def create_work_issue(summary)
    create(summary, @@WORK_CATEGORY)
  end

  # その他の課題を作成
  def create_other_issue(summary)
    create(summary, @@OTHER_CATEGORY)
  end

  private
    # 課題を新規作成
    def create(summary, category)
      params = {
        projectId:   @@PROJECT_ID,
        issueTypeId: @@TASK_ISSUE_TYPE,
        categoryId:  [category],
        priorityId:  @@PRIORITY_ID,
      }
      @backlog.create_issue(summary, params)
      self.list
    end

end

def help
  puts "-l     課題を一覧"
  puts "-u id  課題のURLを表示"
  puts "-e id  課題をクローズ"
  puts "-sd summary 開発関係の課題を作成"
  puts "-sw summary 仕事関係の課題を作成"
  puts "-so summary その他の課題を作成"
  puts "-h     ヘルプを表示"
  exit
end

backlog = PrivateBacklogger.new
argv = ARGV.getopts('lu:se:d:w:o:h')
argv['h'] and help
argv['l'] and backlog.list              # 一覧表示
argv['u'] and backlog.url(argv['u'])    # URL表示
argv['e'] and backlog.close(argv['e'])  # 課題クローズ
if argv['s']
  argv['d'] and backlog.create_develop_issue(argv['d']) # 開発関係の課題作成
  argv['w'] and backlog.create_work_issue(argv['w'])    # 仕事関係の課題作成
  argv['o'] and backlog.create_other_issue(argv['o'])   # その他の課題作成
end
