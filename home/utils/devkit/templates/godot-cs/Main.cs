using Godot;

public partial class Main : Node
{
	public override void _Ready()
	{
		GD.Print("hello from Godot (C#)");
		GetTree().Quit();
	}
}
