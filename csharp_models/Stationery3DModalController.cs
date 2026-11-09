using System;

namespace Tooler.Stationery.Modals
{
    public enum ModalTransitionState
    {
        Hidden,
        FoldingIn,
        Visible,
        FoldingOut
    }

    /// <summary>
    /// 3D Origami / Notebook Paper Fold-out modal animation controller.
    /// Manages 3D perspective rotation, scale, and paper tape anchor.
    /// </summary>
    public class Stationery3DModalController
    {
        public ModalTransitionState State { get; private set; } = ModalTransitionState.Hidden;
        public double AnimationProgress { get; private set; } = 0.0; // 0.0 to 1.0

        public double RotationXRadians => (1.0 - AnimationProgress) * (Math.PI / 8.0);
        public double ScaleFactor => 0.85 + (0.15 * AnimationProgress);
        public double Opacity => Math.Clamp(AnimationProgress, 0.0, 1.0);

        public void StartOpenAnimation()
        {
            State = ModalTransitionState.FoldingIn;
            AnimationProgress = 0.0;
        }

        public void Update(double deltaTimeSeconds, double durationSeconds = 0.38)
        {
            if (State == ModalTransitionState.FoldingIn)
            {
                AnimationProgress += deltaTimeSeconds / durationSeconds;
                if (AnimationProgress >= 1.0)
                {
                    AnimationProgress = 1.0;
                    State = ModalTransitionState.Visible;
                }
            }
            else if (State == ModalTransitionState.FoldingOut)
            {
                AnimationProgress -= deltaTimeSeconds / durationSeconds;
                if (AnimationProgress <= 0.0)
                {
                    AnimationProgress = 0.0;
                    State = ModalTransitionState.Hidden;
                }
            }
        }

        public void StartCloseAnimation()
        {
            State = ModalTransitionState.FoldingOut;
        }
    }
}
