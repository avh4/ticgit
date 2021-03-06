require File.dirname(__FILE__) + "/spec_helper"

describe TicGit::Base do 
  include TicGitSpecHelper
  
  before(:each) do 
    @path = setup_new_git_repo
    @orig_test_opts = test_opts
    @ticgit = TicGit.open(@path, @orig_test_opts)
  end
  
  it "should have 4 ticket states" do
    @ticgit.tic_states.size.should eql(4)
  end
  
  it "should be able to create new tickets" do
    @ticgit.tickets.size.should eql(0)
    @ticgit.ticket_new('my new ticket').should be_an_instance_of(TicGit::Ticket)
    @ticgit.tickets.size.should eql(1)
  end
  
  it "should be able to list existing tickets" do
    @ticgit.ticket_new('my new ticket').should be_an_instance_of(TicGit::Ticket)
    @ticgit.ticket_new('my second ticket').should be_an_instance_of(TicGit::Ticket)
    list = @ticgit.ticket_list
    list.first.should be_an_instance_of(TicGit::Ticket)
    list.size.should eql(2)
  end
  
  describe "assigning tickets" do
    it "should be able to change to whom the ticket is assigned" do
      @ticgit.ticket_new('my new ticket').should be_an_instance_of(TicGit::Ticket)
      @ticgit.ticket_new('my second ticket').should be_an_instance_of(TicGit::Ticket)
      tic = @ticgit.ticket_list.first
      @ticgit.ticket_assign('pope', tic.ticket_id)
      tic = @ticgit.ticket_show(tic.ticket_id)
      tic.assigned.should eql('pope')
    end
  
    it "should not be able to change to whom the ticket is assigned if it is already assigned to that user" do
      @ticgit.ticket_new('my new ticket').should be_an_instance_of(TicGit::Ticket)
      @ticgit.ticket_new('my second ticket').should be_an_instance_of(TicGit::Ticket)
      tic = @ticgit.ticket_list.first
      tic_id = tic.ticket_id
      lambda {
        @ticgit.ticket_assign(tic.assigned, tic_id)
        @ticgit.ticket_show(tic_id)
      }.should_not change(@ticgit.ticket_recent(tic_id), :size)
    end
  
    it "should default to the current user when changing to whom the ticket is assigned" do
      @ticgit.ticket_new('my new ticket').should be_an_instance_of(TicGit::Ticket)
      @ticgit.ticket_new('my second ticket').should be_an_instance_of(TicGit::Ticket)
      tic = @ticgit.ticket_list.first
      @ticgit.ticket_checkout(tic.ticket_id)
      @ticgit.ticket_assign()
      tic = @ticgit.ticket_show(tic.ticket_id)
      tic.assigned.should eql(tic.email)
    end
  end
  
  describe "ticket states" do
    it "should be able to change the state of a ticket" do
      @ticgit.ticket_new('my new ticket').should be_an_instance_of(TicGit::Ticket)
      @ticgit.ticket_new('my second ticket').should be_an_instance_of(TicGit::Ticket)
      tic = @ticgit.ticket_list.first
      @ticgit.ticket_change('resolved', tic.ticket_id)
      tic = @ticgit.ticket_show(tic.ticket_id)
      tic.state.should eql('resolved')
    end

    it "should not be able to change the state of a ticket to something invalid" do
      @ticgit.ticket_new('my new ticket').should be_an_instance_of(TicGit::Ticket)
      @ticgit.ticket_new('my second ticket').should be_an_instance_of(TicGit::Ticket)
      tic = @ticgit.ticket_list.first
      @ticgit.ticket_change('resolve', tic.ticket_id)
      tic = @ticgit.ticket_show(tic.ticket_id)
      tic.state.should_not eql('resolve')
    end
    
    it "should only show open tickets by default" do
      @ticgit.ticket_new('my third ticket')
      tics = @ticgit.ticket_list
      states = tics.map { |t| t.state }.uniq
      states.size.should eql(1)
      states.first.should eql('open')
    end
  end
  
  describe "filtering tickets" do
    it "should be able to filter tickets on state" do
      @ticgit.ticket_new('my new ticket').should be_an_instance_of(TicGit::Ticket)
      @ticgit.ticket_new('my second ticket').should be_an_instance_of(TicGit::Ticket)
      @ticgit.ticket_new('my third ticket')
      tic = @ticgit.ticket_list.first
      @ticgit.ticket_change('resolved', tic.ticket_id)
      tics = @ticgit.ticket_list(:state => 'resolved')
      tics.size.should eql(1)
      tics = @ticgit.ticket_list(:state => 'open')
      tics.size.should eql(2)
    end
  
    it "should be able to save and recall filtered ticket lists" do
      @ticgit.ticket_new('my new ticket').should be_an_instance_of(TicGit::Ticket)
      @ticgit.ticket_new('my second ticket').should be_an_instance_of(TicGit::Ticket)
      tic = @ticgit.ticket_list.first
      @ticgit.ticket_change('resolved', tic.ticket_id)
      tics = @ticgit.ticket_list(:state => 'resolved', :save => 'resolve')
      tics.size.should eql(1)
      rtics = @ticgit.ticket_list(:saved => 'resolve')
      tics.size.should eql(1)
    end
  end
  
  describe "commenting on tickets" do 
    it "should be able to comment on tickets" do
      t = @ticgit.ticket_new('my fourth ticket')
      t.comments.size.should eql(0)
  
      @ticgit.ticket_comment('my new comment', t.ticket_id)
      t = @ticgit.ticket_show(t.ticket_id)
      t.comments.size.should eql(1)
      t.comments.first.comment.should eql('my new comment')
    end
  end
  
  it "should retrieve specific tickets" do
    t = @ticgit.ticket_new('my fourth ticket')
    tid = @ticgit.ticket_list.last.ticket_id
    tic = @ticgit.ticket_show(tid)
    tic.ticket_id.should eql(tid)
  end
  
  it "should be able to checkout a ticket" do
    t = @ticgit.ticket_new('my fourth ticket')
    tid = @ticgit.ticket_list.last.ticket_id
    @ticgit.ticket_checkout(tid)
    @ticgit.ticket_show.ticket_id.should eql(tid)
  end

  it "should resolve partial shas into ticket" do 
    t = @ticgit.ticket_new('my fourth ticket')
    tid = @ticgit.ticket_list.last.ticket_id
    @ticgit.ticket_checkout(tid[0, 5])
    @ticgit.ticket_show.ticket_id.should eql(tid)
  
    @ticgit.ticket_checkout(tid[0, 20])
    @ticgit.ticket_show.ticket_id.should eql(tid)
  end
  
  it "should resolve order number from most recent list into ticket" do 
    @ticgit.ticket_new('my new ticket').should be_an_instance_of(TicGit::Ticket)
    @ticgit.ticket_new('my second ticket').should be_an_instance_of(TicGit::Ticket)
    tics = @ticgit.ticket_list(:state => 'open')
    @ticgit.ticket_show('1').ticket_id.should eql(tics[0].ticket_id)
    @ticgit.ticket_show('2').ticket_id.should eql(tics[1].ticket_id)
  end

  describe "tagging tickets" do
    it "should be able to tag a ticket" do
      @ticgit.ticket_new('my new ticket').should be_an_instance_of(TicGit::Ticket)
      @ticgit.ticket_new('my second ticket').should be_an_instance_of(TicGit::Ticket)
      t = @ticgit.ticket_list.last
      t.tags.size.should eql(0)
      @ticgit.ticket_tag('newtag', t.ticket_id)
      t = @ticgit.ticket_show(t.ticket_id)
      t.tags.size.should eql(1)
      t.tags.first.should eql('newtag')
    end

    it "should not be able to tag a ticket with a blank tag" do
      t = @ticgit.ticket_new('my fourth ticket', :tags => [' '])
      t.tags.size.should eql(0)
  
      @ticgit.ticket_tag(' ', t.ticket_id)
      t = @ticgit.ticket_show(t.ticket_id)
      t.tags.size.should eql(0)

      @ticgit.ticket_tag('', t.ticket_id)
      t = @ticgit.ticket_show(t.ticket_id)
      t.tags.size.should eql(0)

      @ticgit.ticket_tag(',mytag', t.ticket_id)
      t = @ticgit.ticket_show(t.ticket_id)
      t.tags.size.should eql(1)
      t.tags.first.should eql('mytag')
    end

    it "should be able to remove a tag from a ticket" do
      t = @ticgit.ticket_new('my next ticket', :tags => ['scotty', 'chacony'])
      t.tags.size.should eql(2)
  
      @ticgit.ticket_tag('scotty', t.ticket_id, :remove => true)
      t.tags.size.should eql(2)
      t.tags.first.should eql('chacony')
    end
  end

  it "should save state to disk after a new ticket" do
    time = File.stat(@ticgit.state).size
    t = @ticgit.ticket_new('my next ticket', :tags => ['scotty', 'chacony'])
    File.stat(@ticgit.state).size.should_not eql(time)
  end
  
  describe "estimating ticket points" do
    it "should be able to change the points of a ticket" do
      @ticgit.ticket_new('my new ticket').should be_an_instance_of(TicGit::Ticket)
      tic = @ticgit.ticket_list.first
      tic.state.should_not eql(3)
      @ticgit.ticket_points(3, tic.ticket_id)
      tic = @ticgit.ticket_show(tic.ticket_id)
      tic.points.should eql(3)
    end
    
  end

end

